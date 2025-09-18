shader_type spatial;

varying vec3 normalized_position;

uniform vec3 zone_size = vec3(1.0, 1.0, 1.0);
uniform float line_width = 0.3;
uniform vec4 outer_color : source_color = vec4(1.0, 0.0, 0.0, 0.8);
uniform vec4 inner_color : source_color = vec4(1.0, 0.0, 0.0, 0.3);
uniform float stripe_density = 20.0;
uniform float stripe_angle_degrees : hint_range(0.0, 360.0) = 30;

void vertex() {
  vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
  vec3 local_position = world_position - NODE_POSITION_WORLD;
  normalized_position = (local_position / zone_size) + vec3(0.5);
}

vec3 box_pct(vec3 _st, vec3 _size, float _smooth) {
  vec3 thres = vec3(0.5) - _size * 0.5;
  vec3 aa = vec3(_smooth * 0.5);
  vec3 pct = smoothstep(thres, thres + aa, _st);
  pct *= smoothstep(thres, thres + aa, vec3(1.0) - _st);
  return pct;
}

float stripe(vec2 st, float _angle, float _density, float sm) {
  float d = sin(_angle) * st.x - cos(_angle) * st.y;
  d = fract(d * _density);
  return smoothstep(0.0, sm, d) * smoothstep(0.5, 0.5 + sm, 1.0 - d);
}

float band(float _x, float _width, float _smooth) {
  float thres = _width * 0.5;
  float aa = _smooth * 0.5;
  return smoothstep(-thres, -thres + aa, _x) -
         smoothstep(thres - aa, thres, _x);
}

void fragment() {
  vec3 st = normalized_position;
  vec4 color = outer_color;

  // frame
  vec3 box_pct = box_pct(st, vec3(1.0) - vec3(line_width) / zone_size, 0.001);
  float sum = box_pct.x + box_pct.y + box_pct.z;
  color = mix(color, inner_color, band(sum - 2.0, 0.01, 0.0));

  // stripe on top
  {
    vec2 st = st.xz;
    float pct = 0.0;
    pct = stripe(st + vec2(0.0, TIME / 10.0), stripe_angle_degrees * PI / 180.0,
                 stripe_density, 0.01);
    color = mix(color, outer_color, pct);
  }

  ALBEDO = color.rgb;
  ALPHA = color.a;
}
