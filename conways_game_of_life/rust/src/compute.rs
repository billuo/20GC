use godot::prelude::*;

#[derive(GodotClass)]
#[class(base=Node, init)]
struct GridCompute {
    size: Vector2i,
    population: u32,
    data_1: PackedByteArray,
    data_2: PackedByteArray,
    base: Base<Node>,
    #[var]
    auto_parallel: bool,
    #[var]
    parallel: bool,
}

#[godot_api]
impl GridCompute {
    #[func]
    fn reset(&mut self, size: Vector2i) {
        assert!(size.x > 0);
        assert!(size.y > 0);
        let n = (size.x * size.y) as usize;
        self.size = size;
        self.population = 0;
        self.data_1.clear();
        self.data_1.resize(n);
        self.data_2.clear();
        self.data_2.resize(n);
    }

    #[func]
    fn set_data(&mut self, data: PackedByteArray) {
        self.data_1 = data;
        self.population = self
            .data_1
            .as_slice()
            .iter()
            .fold(0, |acc, &x| if x == 0 { acc } else { acc + 1 });
    }

    #[func]
    fn render_image(&mut self) -> PackedByteArray {
        PackedByteArray::from_iter(
            self.data_1
                .as_slice()
                .iter()
                .map(|&byte| if byte != 0 { 255 } else { 0 }),
        )
    }

    #[func]
    fn get_population(&self) -> u32 {
        self.population
    }

    #[func]
    fn get_cell(&self, cell_pos: Vector2i) -> u8 {
        let data = self.data_1.as_slice();
        let idx = cell_pos.x + cell_pos.y * self.size.x;
        data[idx as usize]
    }

    #[func]
    fn set_cell(&mut self, cell_pos: Vector2i, byte: u8) {
        let data = self.data_1.as_mut_slice();
        let idx = cell_pos.x + cell_pos.y * self.size.x;
        data[idx as usize] = byte;
    }

    #[func]
    fn step(&mut self, b_mask: u8, s_mask: u8) {
        self.population = 0;

        let parallel = self.parallel || (self.auto_parallel && self.size.x * self.size.y >= 4000);
        if parallel {
            use rayon::prelude::*;
            struct MySlice<'a>(&'a [u8]);
            unsafe impl<'a> Send for MySlice<'a> {}
            let cur = MySlice(self.data_1.as_slice());
            let get_cur_cell = |c: Vector2i| -> u8 {
                if c.x < 0 || c.y < 0 || c.x >= self.size.x || c.y >= self.size.y {
                    return 0;
                }
                cur.0[(c.x + c.y * self.size.x) as usize]
            };
            let v = self
                .data_1
                .as_slice()
                .par_iter()
                .enumerate()
                .map(|(idx, &byte)| {
                    let x = idx as i32 % self.size.x;
                    let y = idx as i32 / self.size.x;
                    let coord = Vector2i::new(x, y);
                    let n0 = get_cur_cell(coord + Vector2i::new(-1, -1));
                    let n1 = get_cur_cell(coord + Vector2i::new(0, -1));
                    let n2 = get_cur_cell(coord + Vector2i::new(1, -1));
                    let n3 = get_cur_cell(coord + Vector2i::new(-1, 0));
                    let n5 = get_cur_cell(coord + Vector2i::new(1, 0));
                    let n6 = get_cur_cell(coord + Vector2i::new(-1, 1));
                    let n7 = get_cur_cell(coord + Vector2i::new(0, 1));
                    let n8 = get_cur_cell(coord + Vector2i::new(1, 1));
                    let n_alive = n0 + n1 + n2 + n3 + n5 + n6 + n7 + n8;
                    let currently_alive = byte != 0;
                    let next_alive = if currently_alive {
                        // check against s_mask if can survive
                        (s_mask & (0x01 << n_alive)) != 0
                    } else {
                        // check against b_mask if should be born
                        (b_mask & (0x01 << n_alive)) != 0
                    };
                    next_alive as u8
                })
                .collect::<Vec<_>>();
            self.population = v
                .iter()
                .fold(0, |acc, &x| if x == 0 { acc } else { acc + 1 });
            // TODO: update population
            self.data_2.as_mut_slice().copy_from_slice(&v);
        } else {
            let get_cur_cell = |c: Vector2i| -> u8 {
                if c.x < 0 || c.y < 0 || c.x >= self.size.x || c.y >= self.size.y {
                    return 0;
                }
                self.data_1[(c.x + c.y * self.size.x) as usize]
            };
            for (idx, &byte) in self.data_1.as_slice().iter().enumerate() {
                let x = idx as i32 % self.size.x;
                let y = idx as i32 / self.size.x;
                let coord = Vector2i::new(x, y);
                let n0 = get_cur_cell(coord + Vector2i::new(-1, -1));
                let n1 = get_cur_cell(coord + Vector2i::new(0, -1));
                let n2 = get_cur_cell(coord + Vector2i::new(1, -1));
                let n3 = get_cur_cell(coord + Vector2i::new(-1, 0));
                let n5 = get_cur_cell(coord + Vector2i::new(1, 0));
                let n6 = get_cur_cell(coord + Vector2i::new(-1, 1));
                let n7 = get_cur_cell(coord + Vector2i::new(0, 1));
                let n8 = get_cur_cell(coord + Vector2i::new(1, 1));
                let n_alive = n0 + n1 + n2 + n3 + n5 + n6 + n7 + n8;
                let currently_alive = byte != 0;
                let next_alive = if currently_alive {
                    // check against s_mask if can survive
                    (s_mask & (0x01 << n_alive)) != 0
                } else {
                    // check against b_mask if should be born
                    (b_mask & (0x01 << n_alive)) != 0
                };
                self.data_2[idx] = next_alive as u8;
                self.population += next_alive as u32;
            }
        }
        std::mem::swap(&mut self.data_1, &mut self.data_2)
    }

    #[func]
    fn randomize(&mut self, ratio: f32) {
        self.population = crate::util::GridUtil::do_randomize(&mut self.data_1, ratio);
    }
}
