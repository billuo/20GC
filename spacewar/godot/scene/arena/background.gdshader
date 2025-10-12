shader_type canvas_item;

// const float NUM_LAYERS = 8.;
// const float CanvasView = 20.;

uniform float star_density = 5.0;
uniform float star_glow = 0.05;
uniform float star_truncate : hint_range(0.0, 1.5) = 1.0;
uniform float flare_shape : hint_range(0.0, 4.0) = 2.7;
uniform float debug_flare_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float debug_flare_angle : hint_range(0.0, 90.0) = 0.0;
// uniform float star_size = 2.0;
// uniform float velocity = 0.25;

vec2 rotate_2d(vec2 _st, float _angle) {
  _st -= 0.5;
  vec2 x = vec2(cos(_angle), -sin(_angle));
  vec2 y = vec2(sin(_angle), cos(_angle));
  _st = mat2(x, y) * _st;
  _st += 0.5;
  return _st;
}

float almost_identity(float x, float thres, float min) {
  if (x > thres)
    return x;
  float a = 2.0 * min - thres;
  float b = 2.0 * thres - 3.0 * min;
  float t = x / thres;
  return (a * t + b) * t * t + min;
}

float noise(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float star(vec2 uv, float _flare, float _flare_angle) {
  uv = rotate_2d(uv, _flare_angle);
  uv = (uv - 0.5) * 2.0;
  uv = abs(uv);
  float d = length(uv);
  float star_pct = star_glow / d;
  float flare_pct =
      smoothstep(-3.0, 0.0, uv.x * uv.y * pow(10.0, flare_shape) - 1.0);
  flare_pct = (1.0 - flare_pct) * _flare;
  float pct = star_pct + flare_pct;
  pct *= 1.0 - smoothstep(0.1, star_truncate, d);
  return pct;
}

vec3 stars(vec2 uv) {
  vec3 total_color = vec3(0.0);
  vec2 id = floor(uv);
  vec2 st = fract(uv);
  for (int y = -1; y <= 1; ++y) {
    for (int x = -1; x <= 1; ++x) {
      vec2 o = vec2(float(x), float(y));
      float r = noise(id + o);
      float size = almost_identity(r, 0.1, 0.05);
      float flare_rot_freq = mix(0.002, 0.02, fract(r * 3.07));
      float flare_rot_amp = mix(PI / 6.0, PI / 2.0, r);
      float flare_rot_phase = r * PI;
      float flare_angle =
          flare_rot_amp * cos(TIME * TAU * flare_rot_freq) + flare_rot_phase;
      float star = star(st - o - vec2(r, fract(r * 34.97)),
                        smoothstep(.1, 1.1, size), flare_angle);
      vec3 color = mix(vec3(0.75), vec3(1.0),
                       sin(vec3(.2, .3, .9) * fract(r * 2345.2) * TAU));
      color = color * vec3(.9, .59, .9 + size);
      total_color += star * size * color;
    }
  }
  return total_color;
}

void fragment() {
  vec2 uv = UV;
  vec3 color = vec3(0.0);

  color = stars(uv * star_density);
  COLOR.rgb = color;
}
