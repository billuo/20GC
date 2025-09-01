shader_type canvas_item;

uniform float interval = 2.0;
uniform float size = 80.0;
uniform vec3 fg = vec3(1.0);
uniform vec3 bg = vec3(0.0);

// void fragment() {
//   vec2 tile_size = vec2(size);
//   vec2 tile_coord = floor(FRAGCOORD.xy / tile_size);
//   vec2 tile_center = (tile_coord + vec2(0.5)) * tile_size;
//   float t = mod(TIME, interval) / interval; // [0, 1)
//   t = (cos(t * PI) + 1.0) / 2.0;
//   float d = dot(abs(FRAGCOORD.xy - tile_center), vec2(1));
//   bool in_range = false;
//   float step_x = 1.0;
//   if (t < 0.5) {
//     in_range = (size - t * size) <= d || d < (size / 2.0 - t * size);
//   } else {
//     in_range = (size - t * size) <= d && d < (size * 1.5 - t * size);
//   }
//   if (in_range) {
//     float m = smoothstep(0.0, 1, step_x) * 0.5;
//     COLOR = mix(COLOR, vec4(0.0, 0.0, 0.0, 1.0), m);
//   }
// }

vec2 rotate2D(vec2 _st, float _angle) {
  _st -= 0.5;
  vec2 x = vec2(cos(_angle), -sin(_angle));
  vec2 y = vec2(sin(_angle), cos(_angle));
  _st = mat2(x, y) * _st;
  _st += 0.5;
  return _st;
}

float box(vec2 _st, vec2 _size, float _smooth) {
  vec2 thres = vec2(0.5) - _size * 0.5;
  vec2 aa = vec2(_smooth * 0.5);
  vec2 uv = smoothstep(thres, thres + aa, _st);
  uv *= smoothstep(thres, thres + aa, vec2(1.0) - _st);
  return uv.x * uv.y;
}

void fragment() {
  vec2 st = UV;
  vec3 color = bg;
  float t = fract(TIME / interval);
  // t = 0.5 + cos(TIME / interval) * 0.3;

  st = fract(st * vec2(10.0, 7.5));
  st = rotate2D(st, PI / 4.0);
  // st = rotate2D(st, TIME);
  const float sm = 0.001;
  if (t <= 0.5) {
    color = mix(color, fg, box(st, vec2(0.5 - t), sm));
    float pct = 1.0 - box(st, vec2(1.0 - t), sm);
    pct *= box(st, vec2(1.5 - t), sm);
    color = mix(color, fg, pct);
  } else {
    color = mix(color, fg, 1.0 - box(st, vec2(2.0 - t), sm));
    float pct = box(st, vec2(1.5 - t), sm);
    pct *= 1.0 - box(st, vec2(1.0 - t), sm);
    color = mix(color, fg, pct);
  }

  COLOR = vec4(color, 1.0);
}
