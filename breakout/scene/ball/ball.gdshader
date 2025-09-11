shader_type canvas_item;

uniform vec2 look_at = vec2(0.0, -1.0);

float circle(vec2 st, float r, float sm) {
  float d = length(st);
  return 1.0 - smoothstep(r - sm, r, d);
}

void fragment() {
  vec2 st = UV;
  float pct = circle(st - vec2(0.5), 0.5, 0.06);
  vec2 l = look_at / length(look_at);
  pct *= 1.0 - circle(st - vec2(0.5) - 0.25 * l, 0.2, 0.03);
  COLOR = vec4(pct);
}
