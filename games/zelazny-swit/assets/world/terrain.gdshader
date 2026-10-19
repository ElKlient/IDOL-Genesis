shader_type spatial;
render_mode cull_back, diffuse_burley;

// Seven shared, mip-filtered reads. No screen texture, transparency or blur.
uniform sampler2D control_map : filter_linear_mipmap, repeat_disable;
uniform sampler2D grass_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paving_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D paving_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool detailed_normals = true;
varying vec2 ground_point;

void vertex() {
    ground_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz;
}

void fragment() {
    vec4 mask = texture(control_map,(ground_point+vec2(50.0))/100.0);
    vec2 uv = ground_point/1.8;
    vec3 grass = texture(grass_map,uv).rgb;
    vec3 earth = texture(earth_map,uv*.84).rgb;
    vec3 stones = texture(paving_map,ground_point/2.4).rgb;
    // Texture luminance breaks the painted edge at pebble/blade scale.
    float soil = smoothstep(.14,.85,mask.r+(grass.g-.5)*.15);
    float paved = smoothstep(.13,.91,mask.g+(stones.r-.5)*.18);
    vec3 grass_tint = mix(vec3(.22,.30,.13),vec3(.37,.43,.22),mask.b);
    vec3 earth_tint = mix(vec3(.46,.37,.25),vec3(.59,.49,.34),mask.b);
    vec3 stone_tint = vec3(.55,.56,.51);
    ALBEDO = mix(mix(grass*grass_tint,earth*earth_tint,soil),stones*stone_tint,paved);
    ALBEDO *= 1.0-mask.a*.65;
    ROUGHNESS = mix(.97,.86,paved);
    if (detailed_normals) {
        vec3 gn = texture(grass_normal,uv).rgb;
        vec3 en = texture(earth_normal,uv*.84).rgb;
        vec3 pn = texture(paving_normal,ground_point/2.4).rgb;
        NORMAL_MAP = mix(mix(gn,en,soil),pn,paved);
        NORMAL_MAP_DEPTH = .65;
    }
}
