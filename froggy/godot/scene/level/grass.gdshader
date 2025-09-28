shader_type spatial;
render_mode cull_disabled;

group_uniforms Geometry;
uniform float scale = 1.0;
uniform float bend_scale = 0.5;
uniform float bend_power = 2.0;
group_uniforms;

group_uniforms Lighting;
uniform vec3 color_young : source_color = vec3(0.1, 0.6, 0.1);
uniform vec3 color_old : source_color = vec3(0.3, 0.6, 0.1);
uniform vec3 back_light : source_color = vec3(0.2);
group_uniforms;

group_uniforms Patch;
uniform sampler2D patch_noise;
uniform float patch_scale = 10.0;
uniform float patch_min : hint_range(0.0, 1.0) = 0.2;
uniform float patch_max : hint_range(0.0, 1.0) = 0.8;
group_uniforms;

group_uniforms Wind;
uniform sampler2D wind_noise;
uniform float wind_strength = 0.0;
uniform float wind_speed = 0.1;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_bend_ao = 0.5;
group_uniforms;

group_uniforms Avoidance;
uniform bool avoidance_enabled = false;
uniform float object_radius = 1.0;
uniform vec3 object_origin;
group_uniforms;

uniform float cut : hint_range(0.0, 1.0) = 1.0;

varying float height;
varying float patch_factor;
varying float wind_bend;
varying float cut_height;

void vertex() {
  cut_height = cut;
  VERTEX.y = min(VERTEX.y, cut_height);
  height = min(1.0 - UV.y, cut_height);
  mat4 inv_model = inverse(MODEL_MATRIX);

  // bend the grass

  // natural bend
  VERTEX.z -= bend_scale * pow(height, bend_power);
  // object avoidance bend
  float avoid_strength = 0.0;
  if (avoidance_enabled) {
    float object_distance = distance(object_origin, NODE_POSITION_WORLD);
    avoid_strength = max(1.0 - pow(object_distance / object_radius, 2.0), 0.0);
    vec2 avoid_direction = normalize(object_origin.xz - NODE_POSITION_WORLD.xz);
    vec2 local_avoid_direction =
        (inv_model * vec4(avoid_direction.x, 0.0, avoid_direction.y, 0.0)).xz;
    VERTEX.xz -= local_avoid_direction * avoid_strength * height;
    VERTEX.y -= 0.5 * avoid_strength * height;
  }
  // wind bend
  vec2 wind_noise_pos =
      NODE_POSITION_WORLD.xz - TIME * normalize(wind_direction) * wind_speed;
  vec2 local_wind_dir =

      (inv_model * vec4(wind_direction.x, 0.0, wind_direction.y, 0.0)).xz;
  wind_bend = pow(height, 2.0) * wind_strength *
              texture(wind_noise, wind_noise_pos).x * (1.0 - avoid_strength);
  VERTEX.xz += wind_bend * local_wind_dir;

  // size the grass
  patch_factor =
      1.0 - texture(patch_noise, NODE_POSITION_WORLD.xz / patch_scale).x;
  VERTEX *= scale * mix(patch_min, patch_max, patch_factor);

  // TODO: grass loses highlight when cut < 1.0
  NORMAL = mix(NORMAL, vec3(0.0, 1.0, 0.0), pow(height, 2.5));
}

void fragment() {
  if (!FRONT_FACING) {
    NORMAL = -NORMAL;
  }

  AO = height - wind_bend * wind_bend_ao;
  AO_LIGHT_AFFECT = cut_height;

  ALBEDO = mix(color_young, color_old, patch_factor);

  BACKLIGHT = back_light;
  ROUGHNESS = 0.4;
  SPECULAR = 0.15;
}
