shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D needles : source_color, filter_linear_mipmap, repeat_disable;
void vertex() {
    float weight = 1.0-UV.y;
    VERTEX.x += sin(TIME*.8+VERTEX.x*.61+VERTEX.z*.3)*weight*.035;
    NORMAL = normalize(NORMAL*.3+vec3(0.0,.8,0.0));
}
void fragment() {
    vec4 spray = texture(needles,UV);
    ALBEDO = spray.rgb*COLOR.rgb;
    ALPHA = spray.a;
    ALPHA_SCISSOR_THRESHOLD = .45;
    ROUGHNESS = .95;
}
