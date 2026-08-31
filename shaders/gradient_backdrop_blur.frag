#version 320 es
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform float u_blur_radius;
uniform float u_header_height;
uniform float u_pass_index;
uniform float u_pass_count;
uniform float u_edge;
uniform float u_extent;
uniform sampler2D u_texture;

out vec4 frag_color;

vec4 sample_clamped(vec2 uv) {
  return texture(u_texture, clamp(uv, vec2(0.0), vec2(1.0)));
}

void main() {
  vec2 frag_coord = FlutterFragCoord();
  vec2 uv = frag_coord / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  uv = clamp(uv, vec2(0.0), vec2(1.0));

  if (u_header_height <= 0.0) {
    frag_color = sample_clamped(uv);
    return;
  }

  // [u_extent] is the length of the radius transition measured from the
  // clear edge. Above/below that transition the radius stays at its maximum.
  float extent = clamp(u_extent, 0.0, 1.0);
  float distance_from_clear_edge = u_edge < 0.5
      ? frag_coord.y
      : u_header_height - frag_coord.y;
  float fade_start = u_header_height * (1.0 - extent);
  float radius_factor = 1.0 - smoothstep(
    fade_start,
    u_header_height,
    distance_from_clear_edge
  );
  float radius = max(u_blur_radius * radius_factor, 0.0);

  if (radius < 0.001) {
    frag_color = sample_clamped(uv);
    return;
  }

  float pass_count = max(u_pass_count, 1.0);
  float pass_radius = radius * (
    0.5 + (
      (clamp(u_pass_index, 0.0, pass_count - 1.0) + 0.5) / pass_count
    )
  );
  vec2 offset = vec2(pass_radius * 0.70710678) / u_size;

  // Five equally weighted taps are used on every nested pass. The output is
  // always a full-color sample; radius zero means an unblurred sample, never
  // transparent pixels.
  frag_color = (
    sample_clamped(uv) +
    sample_clamped(uv + offset) +
    sample_clamped(uv + vec2(-offset.x, offset.y)) +
    sample_clamped(uv + vec2(offset.x, -offset.y)) +
    sample_clamped(uv - offset)
  ) * 0.2;
}
