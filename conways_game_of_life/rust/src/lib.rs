use godot::prelude::*;

pub mod compute;
pub mod util;

struct MyExtension;
#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
