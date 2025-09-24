shader_type spatial;

uniform vec3 color_main : source_color = vec3(0.55, 0.61, 0.96);
uniform vec3 color_highlight : source_color = vec3(0.9);
uniform vec2 scale = vec2(1.0);
uniform float highlight_width : hint_range(0.0, 1.0) = 0.1;
uniform float highlight_smooth : hint_range(0.0, 1.0) = 0.03;

// random point within unit square based on input
vec2 random2(vec2 p) {
  return fract(
      sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) *
      43758.5453);
}

// ref: https://iquilezles.org/articles/voronoilines/

// returns (distance to closest point, distance to second closest point)
// oA: vector from st to closest point
// oB: vector from st to second closest point
vec2 voronoi(in vec2 st, out vec2 oA, out vec2 oB) {
  ivec2 st_int = ivec2(floor(st));
  vec2 st_fract = fract(st);
  vec2 res = vec2(1.0);
  for (int y = -1; y <= 1; ++y) {
    for (int x = -1; x <= 1; ++x) {
      ivec2 nb = ivec2(x, y);
      vec2 rel = vec2(nb) + random2(vec2(st_int + nb)) - st_fract;
      float d_squared = dot(rel, rel);
      if (d_squared < res.x) {
        res.y = res.x;
        res.x = d_squared;
        oA = rel;
      } else if (d_squared < res.y) {
        res.y = d_squared;
        oB = rel;
      }
    }
  }
  return sqrt(res);
}

float voronoi_distance(in vec2 st) {
  ivec2 st_int = ivec2(floor(st));
  vec2 st_fract = fract(st);

  // first pass: find `nb` and `rel` for closest point
  ivec2 min_nb;
  vec2 min_rel;
  {
    float res = 4.0;
    for (int y = -1; y <= 1; ++y) {
      for (int x = -1; x <= 1; ++x) {
        ivec2 nb = ivec2(x, y);
        vec2 rel = vec2(nb) + random2(vec2(st_int + nb)) - st_fract;
        float d_squared = dot(rel, rel);
        if (d_squared < res) {
          res = d_squared;
          min_nb = nb;
          min_rel = rel;
        }
      }
    }
  }

  // second pass: the usual voronoi,
  // but centered around the cell containing the actual closest point to st
  float distance = 4.0;
  for (int y = -2; y <= 2; ++y) {
    for (int x = -2; x <= 2; ++x) {
      ivec2 nb = min_nb + ivec2(x, y);
      vec2 rel = vec2(nb) + random2(vec2(st_int + nb)) - st_fract;
      float d = dot(0.5 * (min_rel + rel), normalize(rel - min_rel));
      distance = min(distance, d);
    }
  }
  return distance;
}

// worst
float voronoi_border_f2_f1(in vec2 st) {
  vec2 a, b;
  vec2 distances = voronoi(st, a, b);
  float d = distances.y - distances.x;
  return 1.0 - smoothstep(0.0, 0.05, d);
}

// better
float voronoi_border_f2_f1_improved(in vec2 st) {
  vec2 a, b;
  vec2 distances = voronoi(st, a, b);
  float d = dot(0.5 * (a + b), normalize(b - a));
  return 1.0 - smoothstep(0.0, 0.05, d);
}

// best
float voronoi_border(in vec2 st, in float width, in float sm) {
  float d = voronoi_distance(st);
  return 1.0 - smoothstep(width - sm, width, 2.0 * d);
}

void fragment() {
  vec2 st = UV * scale;
  vec3 color = vec3(1.0, 0.0, 1.0);
  color = mix(color_main, color_highlight,
              voronoi_border(st, highlight_width, highlight_smooth));

  // fake AO
  // const float gap = 0.02;
  // const float sm = 0.01;
  // float d = 1.0 - (smoothstep(gap, gap + sm, UV.y) -
  //                  smoothstep(1.0 - gap - sm, 1.0 - gap, UV.y));
  // color = mix(color, vec3(0.0), d * 0.8);

  // ALBEDO.rb = fract(UV);
  // ALBEDO.g = 0.0;

  ALBEDO = color;
}
