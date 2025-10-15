#[compute]
#version 450

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform UniformData {
  int width;
  int height;
  int _padding0;
  int _padding1;
};
layout(set = 0, binding = 1, std430) restrict readonly buffer CurGrid { int data[]; }
cur_grid;
layout(set = 0, binding = 2, std430) restrict writeonly buffer NextGrid { int data[]; }
next_grid;

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
void set_next_grid(ivec2 coord, int byte) {
  int idx = coord.x + coord.y * width;
  atomicAnd(next_grid.data[idx / 4], 0x00 << ((idx % 4) * 8));
  atomicOr(next_grid.data[idx / 4], (byte & 0xff) << ((idx % 4) * 8));
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
  bool next_alive = n4 != 0;
  if (n4 != 0) {
    if (n_alive < 2 || n_alive > 3)
      next_alive = false;
  } else {
    if (n_alive == 3)
      next_alive = true;
  }
  set_next_grid(coord, int(next_alive));
}
