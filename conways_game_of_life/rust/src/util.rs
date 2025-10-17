use std::path::Path;

use godot::prelude::*;

#[derive(GodotClass)]
#[class(no_init)]
pub struct GridUtil {}

impl GridUtil {
    pub(crate) fn do_randomize(bytes: &mut PackedByteArray, alive_ratio: f32) -> u32 {
        use rand::Rng;
        let mut rng = rand::rng();
        let dist = rand::distr::Uniform::new(0.0, 1.0).unwrap();
        let mut population = 0;
        for byte in bytes.as_mut_slice() {
            let alive = rng.sample(dist) < alive_ratio;
            *byte = if alive {
                population += 1;
                1
            } else {
                0
            }
        }
        population
    }

    pub(crate) fn do_blit_rect(
        src: &[u8],
        src_size: Vector2i,
        src_rect: Rect2i,
        dst: &mut [u8],
        dst_size: Vector2i,
        dst_offset: Vector2i,
    ) {
        let src_bound = Rect2i::new(Vector2i::ZERO, src_size);
        let dst_bound = Rect2i::new(Vector2i::ZERO, dst_size);
        let dst_rect = Rect2i::new(dst_offset, src_rect.size);
        assert!(src_bound.has_area());
        assert!(dst_bound.has_area());
        assert!(src_rect.has_area());
        assert!(dst_rect.has_area());
        assert!(src_bound.encloses(src_rect));
        assert!(dst_bound.encloses(dst_rect));
        for y in 0..src_rect.size.y {
            for x in 0..src_rect.size.x {
                let src_coord = src_rect.position + Vector2i::new(x, y);
                let src_idx = src_coord.x + src_coord.y * src_size.x;
                let dst_coord = dst_rect.position + Vector2i::new(x, y);
                let dst_idx = dst_coord.x + dst_coord.y * dst_size.x;
                dst[dst_idx as usize] = src[src_idx as usize];
            }
        }
    }
}

#[godot_api]
impl GridUtil {
    /// Parses Totalistic Life-like rule strings, e.g. B3/S23.
    #[func]
    fn parse_rule_string(s: String) -> Vec<u8> {
        use ca_rules::ParseLife;
        struct Rule {
            b: Vec<u8>,
            s: Vec<u8>,
        }
        impl ParseLife for Rule {
            fn from_bs(b: Vec<u8>, s: Vec<u8>) -> Self {
                Rule { b, s }
            }
        }
        if let Ok(Rule { mut b, mut s }) = Rule::parse_rule(&s) {
            b.push(255);
            b.append(&mut s);
            b
        } else {
            vec![]
        }
    }

    #[func]
    fn parse_file(path: String) -> Option<Gd<ParsedPattern>> {
        let path = std::path::Path::new(&path);
        if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
            match ext {
                "rle" => match parse_file_rle(path) {
                    Ok(parsed) => return Some(Gd::from_object(parsed)),
                    Err(e) => godot_error!("failed to parse {}: {}", path.display(), e),
                },
                "cell" => (),
                _ => (),
            }
        }
        None
    }

    #[func]
    fn randomize(mut bytes: PackedByteArray, alive_ratio: f32) -> Dictionary {
        let population = Self::do_randomize(&mut bytes, alive_ratio);
        let mut d = Dictionary::new();
        d.set("data".to_godot(), bytes);
        d.set("population".to_godot(), population);
        d
    }

    #[func]
    fn render_image(bytes: PackedByteArray) -> PackedByteArray {
        PackedByteArray::from_iter(
            bytes
                .as_slice()
                .iter()
                .map(|&byte| if byte != 0 { 255 } else { 0 }),
        )
    }

    #[func]
    fn blit_rect(
        src: PackedByteArray,
        src_size: Vector2i,
        src_rect: Rect2i,
        mut dst: PackedByteArray,
        dst_size: Vector2i,
        dst_offset: Vector2i,
    ) -> PackedByteArray {
        Self::do_blit_rect(
            src.as_slice(),
            src_size,
            src_rect,
            dst.as_mut_slice(),
            dst_size,
            dst_offset,
        );
        dst
    }
}

#[derive(GodotClass)]
#[class(init)]
pub struct ParsedPattern {
    #[var]
    pub size: Vector2i,
    #[var]
    pub rule: GString,
    #[var]
    pub bytes: PackedByteArray,
}

use ca_formats::rle::Rle;
fn parse_file_rle(path: &Path) -> anyhow::Result<ParsedPattern> {
    use std::fs::File;
    let file = File::open(path)?;
    let rle = Rle::new_from_file(file)?;
    let header_data = rle
        .header_data()
        .ok_or(anyhow::anyhow!("rle has no header data"))?;
    let size = Vector2i::new(header_data.x.try_into()?, header_data.y.try_into()?);
    let rule = header_data
        .rule
        .as_ref()
        .map(|s| s.to_godot())
        .unwrap_or_default();
    let mut bytes = PackedByteArray::new();
    bytes.resize((size.x * size.y) as usize);
    for cell in rle {
        let cell = cell?;
        let pos = cell.position;
        let idx = (pos.0 + pos.1 * size.x as i64) as usize;
        bytes.as_mut_slice()[idx] = 1;
    }
    Ok(ParsedPattern { size, rule, bytes })
}
