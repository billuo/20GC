use godot::classes::INode;
use godot::classes::Node;
use godot::prelude::*;

pub(crate) mod position;
pub(crate) mod solver;
pub(crate) mod transposition;

#[derive(GodotClass)]
#[class(base=Node)]
struct C4Solver {
    base: Base<Node>,
}
#[godot_api]
impl INode for C4Solver {
    fn init(base: Base<Node>) -> Self {
        godot_print!("Hello, world!");
        Self { base }
    }
}

#[godot_api]
impl C4Solver {
    #[func]
    fn solve() -> i32 {
        todo!()
    }
}

impl C4Solver {}

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
