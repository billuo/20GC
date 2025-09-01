shader_type canvas_item;

uniform vec2 brick_size = vec2(80.0, 20.0);
uniform float round_corner = 6.0;

// (ax)^2 + (by)^2 = 1
float oval(vec2 _st, vec2 _ab, float _smooth) {
  _st = _st * 2.0 - 1.0;
  float d = dot(_st * _ab, _st * _ab);
  return 1.0 - smoothstep(1.0, 1.0 + _smooth, d);
}

float box(vec2 _st, vec2 _size, float _smooth) {
  vec2 thres = vec2(0.5) - _size * 0.5;
  vec2 aa = vec2(_smooth * 0.5);
  vec2 uv = smoothstep(thres, thres + aa, _st);
  uv *= smoothstep(thres, thres + aa, vec2(1.0) - _st);
  return uv.x * uv.y;
}

// float rounded_box(vec2 _st, vec2 _size, float _radius, float _smooth) {
//   _st = _st * 2.0 - 1.0;
//   float d = length(max(vec2(0.0), abs(_st) - _size + _radius));
//   return 1.0 - smoothstep(_radius, _radius + _smooth, d);
// }

void fragment() {
  vec2 st = UV;
  vec3 color = vec3(0.0);
  vec3 main_color = COLOR.rgb;
  float original_alpha = COLOR.a;
  float sm = 0.0;

  float r = round_corner;
  //r = 5.0 + 5.0 * cos(TIME);
  vec2 rr = clamp(vec2(r) / brick_size, vec2(0.0), vec2(0.5));
  sm = 0.001;
  color = mix(color, main_color, box(st, vec2(1.0 - 2.0 * rr.x, 1.0), sm));
  color = mix(color, main_color, box(st, vec2(1.0, 1.0 - 2.0 * rr.y), sm));
  vec2 offset = vec2(.5) - rr;
  vec2 ab = 0.5 / rr;
  sm = 0.3;
  color = mix(color, main_color, oval(st + offset * vec2(1.0, 1.0), ab, sm));
  color = mix(color, main_color, oval(st + offset * vec2(-1.0, 1.0), ab, sm));
  color = mix(color, main_color, oval(st + offset * vec2(1.0, -1.0), ab, sm));
  color = mix(color, main_color, oval(st + offset * vec2(-1.0, -1.0), ab, sm));

  COLOR = vec4(color, original_alpha);
}
