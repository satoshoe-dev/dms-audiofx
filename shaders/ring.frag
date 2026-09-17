// AudioFX: glow ring around the player disc.
//
// Additive like glow.frag: alpha 0, color = light. A soft ring just outside
// the cover whose thickness and brightness breathe with the level; the
// spectrum runs around the circumference (mirrored left and right), plus a
// wide halo and a slowly circling highlight.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    float radius;       // ring radius, fraction of half the edge length
    float thickness;    // base thickness, same unit
    float level;
    float idle;
    float time;
    float strength;
    vec4 color;

    vec4 b0;
    vec4 b1;
    vec4 b2;
    vec4 b3;
} ubuf;

float band(float p) {
    float x = clamp(p, 0.0, 1.0) * 15.0;
    int i = int(floor(x));
    int j = min(i + 1, 15);
    float a[16] = float[16](ubuf.b0.x, ubuf.b0.y, ubuf.b0.z, ubuf.b0.w,
                            ubuf.b1.x, ubuf.b1.y, ubuf.b1.z, ubuf.b1.w,
                            ubuf.b2.x, ubuf.b2.y, ubuf.b2.z, ubuf.b2.w,
                            ubuf.b3.x, ubuf.b3.y, ubuf.b3.z, ubuf.b3.w);
    return mix(a[i], a[j], fract(x));
}

void main() {
    vec2 p = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(p);
    // 0 at the top, clockwise, mirrored: 0 top -> 1 bottom
    float w = atan(p.x, -p.y) / 3.14159265;
    float pos = abs(w);

    float spectrum = band(pos);
    float drive = ubuf.level * 0.7 + spectrum * 0.6 + ubuf.idle;

    // circling highlight
    float turn = ubuf.time * 0.35;
    float spot = pow(0.5 + 0.5 * cos(atan(p.x, -p.y) - turn * 6.2831853), 6.0);
    drive *= 0.8 + 0.4 * spot;

    float thickness = ubuf.thickness * (0.6 + 1.2 * drive);
    float d = (r - ubuf.radius) / max(0.002, thickness);
    float core = exp(-d * d);
    // halo only outward, the cover covers the inside
    float outside = max(0.0, r - ubuf.radius);
    float halo = exp(-outside / max(0.004, ubuf.thickness * (2.5 + 4.0 * drive))) * step(ubuf.radius - thickness, r);

    float light = (core * 1.2 + halo * 0.45) * drive * ubuf.strength;
    light = light / (1.0 + 0.4 * light);
    // fade softly to 0 from the ring all the way to the edge of the surface;
    // fading only over the last 10 % left a faint circular edge visible
    float fade = 1.0 - smoothstep(ubuf.radius, 1.0, r);
    light *= fade * fade;

    vec3 rgb = ubuf.color.rgb * light + vec3(1.0, 0.93, 0.82) * max(0.0, core * drive * ubuf.strength - 1.0) * 0.4;
    fragColor = vec4(rgb, 0.0) * ubuf.qt_Opacity;
}
