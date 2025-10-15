#[compute]
#version 450

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform UniformData {
  int width;
  int height;
  int _padding0;
  int _padding1;
};
layout(set = 0, binding = 1, std430) restrict buffer CurGrid { int data[]; }
cur_grid;
layout(set = 0, binding = 2, std430) restrict buffer NextGrid { int data[]; }
next_grid;
layout(set = 0, binding = 3,
       rgba8) restrict writeonly uniform image2D output_image;

int get_cur_grid(ivec2 coord) {
  if (coord.x < 0 || coord.y < 0 || coord.x >= width || coord.y >= height) {
    return 0;
  }
  return cur_grid.data[coord.x + coord.y * width];
}
void set_next_grid(ivec2 coord, int alive) {
  next_grid.data[coord.x + coord.y * width] = alive;
}
void draw_image(ivec2 coord, int alive) {
  imageStore(output_image, coord, vec4(float(alive)));
}

void main() {
  ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
  if (coord.x >= width || coord.y >= height)
    return;
  int n0 = get_cur_grid(coord + ivec2(-1, -1));
  int n1 = get_cur_grid(coord + ivec2(0, -1));
  int n2 = get_cur_grid(coord + ivec2(1, -1));
  int n3 = get_cur_grid(coord + ivec2(-1, 0));
  int n4 = get_cur_grid(coord + ivec2(0, 0));
  int n5 = get_cur_grid(coord + ivec2(1, 0));
  int n6 = get_cur_grid(coord + ivec2(-1, 1));
  int n7 = get_cur_grid(coord + ivec2(0, 1));
  int n8 = get_cur_grid(coord + ivec2(1, 1));
  int n_alive = n0 + n1 + n2 + n3 + n5 + n6 + n7 + n8;
  int next_alive = n4;
  if (n4 != 0) {
    if (n_alive < 2 || n_alive > 3)
      next_alive = 0;
  } else {
    if (n_alive == 3)
      next_alive = 1;
  }
  set_next_grid(coord, next_alive);
  draw_image(coord, next_alive);
}
