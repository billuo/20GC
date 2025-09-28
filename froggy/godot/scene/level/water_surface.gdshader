shader_type spatial;

uniform vec3 color_main : source_color = vec3(0.55, 0.61, 0.96);
uniform vec3 color_highlight : source_color = vec3(0.9);
uniform vec2 scale = vec2(1.0);
uniform float highlight_width : hint_range(0.0, 1.0) = 0.1;
uniform float highlight_smooth : hint_range(0.0, 1.0) = 0.03;

vec2 noise2(vec2 p) {
  return fract(
      sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) *
      43758.5453);
}

// ref: https://iquilezles.org/articles/voronoilines/
// ref: https://www.shadertoy.com/view/llG3zy
vec3 voronoi_distance(in vec2 x) {
  vec2 n = floor(x - 1.5);
  vec2 f = x - n;
  // first pass: regular voronoi
  vec2 mr;
  float md = 8.0;
  for (int j = 0; j <= 3; j++) {
    for (int i = 0; i <= 3; i++) {
      vec2 g = vec2(float(i), float(j));
      vec2 o = noise2(n + g);
      o = 0.5 + 0.4 * sin(TIME + 2.0 * PI * o);
      vec2 r = g + o - f;
      float d = dot(r, r);
      if (d < md) {
        md = d;
        mr = r;
      }
    }
  }
  // second pass: distance to borders
  md = 8.0;
  for (int j = 0; j <= 3; j++) {
    for (int i = 0; i <= 3; i++) {
      vec2 g = vec2(float(i), float(j));
      vec2 o = noise2(n + g);
      o = 0.5 + 0.4 * sin(TIME + 2.0 * PI * o);
      vec2 r = g + o - f;
      md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
    }
  }

  return vec3(md, mr);
}

float voronoi_border(in vec2 st, in float width, in float sm) {
  float d = voronoi_distance(st).x;
  return 1.0 - smoothstep(width - sm, width, 2.0 * d);
}

void fragment() {
  vec2 st = UV * scale;
  vec3 color = vec3(1.0, 0.0, 1.0);
  color = mix(color_main, color_highlight,
              voronoi_border(st, highlight_width, highlight_smooth));
  ALBEDO = color;
}
