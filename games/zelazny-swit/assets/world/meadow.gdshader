shader_type spatial;
render_mode cull_disabled, diffuse_burley;
varying float blade_height;
void vertex() {
    blade_height = COLOR.a;
    float gust = sin(TIME*1.1+VERTEX.x*.63+VERTEX.z*.49);
    VERTEX.x += gust*.055*blade_height*blade_height;
    VERTEX.z += sin(TIME*.83+VERTEX.x*.31)*.026*blade_height;
    // Soft shared up-facing normals keep thin leaves readable from both sides.
    NORMAL = normalize(NORMAL*.35+vec3(0.0,.85,0.0));
}
void fragment() {
    ALBEDO = mix(vec3(.10,.19,.055),vec3(.37,.44,.17),blade_height)*COLOR.rgb;
    ROUGHNESS = .95;
}
