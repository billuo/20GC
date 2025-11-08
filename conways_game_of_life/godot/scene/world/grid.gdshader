shader_type canvas_item;

uniform vec3 color: source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (COLOR.rgb == vec3(1.0, 0.0, 0.0)) {
		COLOR.rgb = color;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
