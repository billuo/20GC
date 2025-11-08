use godot::classes::INode;
use godot::classes::Node;
use godot::prelude::*;

pub(crate) mod position;
pub(crate) mod solver;
pub(crate) mod transposition;

use position::Position;

#[derive(GodotClass)]
#[class(base=Node)]
struct C4Solver {
    solver: solver::Solver,
    base: Base<Node>,
}
#[godot_api]
impl INode for C4Solver {
    fn init(base: Base<Node>) -> Self {
        godot_print!("Hello, world!");
        Self {
            solver: Default::default(),
            base,
        }
    }
}

#[godot_api]
impl C4Solver {
    #[func]
    fn solve(&mut self, moves: PackedByteArray) -> i32 {
        let mut p = Position::default();
        for col in moves.as_slice() {
            p.play(*col as usize)
        }
        self.solver.solve(&p, false)
    }

    #[func]
    fn rate_next_moves(&mut self, moves: PackedByteArray) -> Array<Variant> {
        let mut p = Position::default();
        for col in moves.as_slice() {
            p.play(*col as usize)
        }
        let mut arr = Array::<Variant>::new();
        arr.resize(Position::WIDTH, &Variant::nil());
        for col in 0..Position::WIDTH {
            if p.can_play(col) {
                let mut newp = p;
                newp.play(col);
                arr.set(col, &self.solver.solve(&p, false).to_variant());
            }
        }
        arr
    }
}

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
