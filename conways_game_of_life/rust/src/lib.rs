use godot::prelude::*;
use rand::Rng;

#[derive(GodotClass)]
#[class(no_init)]
struct GridCPUCompute {}
#[godot_api]
impl GridCPUCompute {
    #[func]
    /// Count number of cells alive in a grid
    fn count_alive(bytes: PackedByteArray) -> u32 {
        let mut n = 0;
        for &byte in bytes.as_slice() {
            n += if byte == 0 { 0 } else { 1 };
        }
        n
    }
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
    fn randomize(mut bytes: PackedByteArray, alive_ratio: f32) -> PackedByteArray {
        let mut rng = rand::rng();
        let dist = rand::distr::Uniform::new(0.0, 1.0).unwrap();
        for byte in bytes.as_mut_slice() {
            let alive = rng.sample(dist) < alive_ratio;
            *byte = if alive { 1 } else { 0 }
        }
        bytes
    }
}

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
