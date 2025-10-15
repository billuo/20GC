#[compute]
#version 450

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform UniformData {
  int width;
  int height;
  int _padding0;
  int _padding1;
};
layout(set = 0, binding = 1, std430) restrict readonly buffer CurGrid {
  int data[];
}
cur_grid;
layout(set = 0, binding = 2,
       r8) restrict writeonly uniform image2D output_image;

int get_cur_grid(ivec2 coord) {
  if (coord.x < 0 || coord.y < 0 || coord.x >= width || coord.y >= height) {
    return 0;
  }
  int idx = coord.x + coord.y * width;
  int chunk = cur_grid.data[idx / 4];
  int byte = chunk & (0xff << ((idx % 4) * 8));
  bool alive = byte != 0;
  return int(alive);
}

void draw_image(ivec2 coord, bool alive) {
  imageStore(output_image, coord, vec4(float(alive)));
}

void main() {
  ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
  if (coord.x >= width || coord.y >= height)
    return;
  int alive = get_cur_grid(coord);
  draw_image(coord, bool(alive));
}
