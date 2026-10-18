class_name SwordFireEffect
extends Node3D
## Original fire rendered in two small draw calls; no lights, particles or assets.
## The blade occupies local Y -0.25 .. -1.2. Equipment materials are untouched.

const FLAME_SHADER: String = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform float effect_time = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float radial_radius = 1.0;
uniform float flame_height_scale = 1.0;
uniform float spark_spread = 0.16;
uniform float spark_rise = 0.68;
uniform float spark_speed = 0.8;
uniform bool burst = false;
varying vec4 fx_data;
varying float spark_life;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise21(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}
void vertex() {
	fx_data = COLOR;
	float seed = COLOR.r * 6.283185;
	float unit_scale = length(MODEL_MATRIX[0].xyz);
	vec3 anchor = VERTEX;
	anchor.xz *= radial_radius;
	vec3 anchor_world = (MODEL_MATRIX * vec4(anchor, 1.0)).xyz;
	spark_life = burst ? clamp(effect_time * spark_speed - COLOR.r * 0.12, 0.0, 1.0)
		: fract(effect_time * spark_speed + COLOR.r);
	if (COLOR.a > 0.5) {
		anchor_world += vec3(sin(seed) * spark_spread * spark_life,
			spark_rise * spark_life * (1.45 - 0.5 * spark_life),
			cos(seed) * spark_spread * spark_life) * unit_scale;
	}
	vec3 anchor_view = (VIEW_MATRIX * vec4(anchor_world, 1.0)).xyz;
	float width = COLOR.g * unit_scale;
	float height = COLOR.b * unit_scale * flame_height_scale;
	float flicker = sin(effect_time * 9.0 + seed) * 0.045;
	vec2 corner = vec2((UV.x - 0.5) * width,
		UV.y * height * (1.0 + flicker));
	corner.x += sin(effect_time * 5.0 + seed + UV.y * 3.0) * UV.y * width * 0.13;
	anchor_view.xy += corner;
	POSITION = PROJECTION_MATRIX * vec4(anchor_view, 1.0);
}
void fragment() {
	vec2 p = vec2((UV.x - 0.5) * 2.0, UV.y);
	float seed = fx_data.r * 20.0;
	if (fx_data.a > 0.5) {
		vec2 q = vec2(p.x, (p.y - 0.5) * 2.0);
		float shape = pow(max(0.0, 1.0 - dot(q, q)), 1.7);
		float fade = sin(spark_life * 3.141593);
		ALBEDO = mix(vec3(1.0, 0.27, 0.025), vec3(1.0, 0.98, 0.83),
			step(0.25, fx_data.r));
		ALPHA = shape * fade * intensity;
	} else {
		float flow = effect_time * 3.8;
		float n = noise21(vec2(p.x * 2.7 + seed, p.y * 5.5 - flow));
		float fine = noise21(vec2(p.x * 6.0 - seed, p.y * 10.0 - flow * 1.5));
		float bend = sin(p.y * 6.0 - effect_time * 7.0 + seed) * 0.33 * p.y;
		float edge = (1.0 - pow(p.y, 0.65)) * (0.53 + n * 0.66);
		float shape = smoothstep(0.0, 0.25, edge - abs(p.x + bend));
		shape *= smoothstep(0.0, 0.07, p.y) * (1.0 - smoothstep(0.70, 1.0, p.y));
		float heat = clamp((1.0 - p.y) * 0.92 - abs(p.x) * 0.80 + fine * 0.16, 0.0, 1.0);
		vec3 color = mix(vec3(1.0, 0.035, 0.005), vec3(1.0, 0.52, 0.035),
			smoothstep(0.16, 0.68, heat));
		color = mix(color, vec3(1.0, 0.91, 0.52), smoothstep(0.70, 0.97, heat));
		ALBEDO = color;
		ALPHA = shape * (0.66 + n * 0.25) * intensity;
	}
}
"""

const CORE_SHADER: String = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform float effect_time = 0.0;
void fragment() {
	float edge = pow(max(0.0, 1.0 - abs(UV.x * 2.0 - 1.0)), 1.7);
	float flow = 0.73 + 0.27 * sin(UV.y * 38.0 - effect_time * 13.0);
	float tip = smoothstep(0.0, 0.08, UV.y) * (1.0 - smoothstep(0.92, 1.0, UV.y));
	ALBEDO = mix(vec3(1.0, 0.12, 0.015), vec3(1.0, 0.76, 0.24), edge * flow);
	ALPHA = edge * tip * (0.48 + flow * 0.22);
}
"""

static var _shared_flame_shader: Shader
static var _shared_core_shader: Shader
var _flame_material: ShaderMaterial
var _core_material: ShaderMaterial
var _burning: bool = false
var _time: float = 0.0

func _ready() -> void:
	name = "SwordFire"
	_build()
	set_burning(_burning)

func set_burning(enabled: bool) -> void:
	_burning = enabled
	visible = enabled
	set_process(enabled)
	if not enabled:
		_time = 0.0
	if is_instance_valid(_flame_material):
		_flame_material.set_shader_parameter("effect_time", _time)
		_core_material.set_shader_parameter("effect_time", _time)

func is_burning() -> bool:
	return _burning

func _process(delta: float) -> void:
	if not _burning or not is_visible_in_tree():
		return
	_time = fmod(_time + delta, 120.0)
	_flame_material.set_shader_parameter("effect_time", _time)
	_core_material.set_shader_parameter("effect_time", _time)

static func flame_material() -> ShaderMaterial:
	if not is_instance_valid(_shared_flame_shader):
		_shared_flame_shader = Shader.new()
		_shared_flame_shader.code = FLAME_SHADER
	var material := ShaderMaterial.new()
	material.shader = _shared_flame_shader
	return material

## Each quad has one anchor; the vertex shader expands it towards the camera.
## Data encodes phase, width, height and 0=flame / 1=spark, in world-sized units.
static func billboard_mesh(anchors: PackedVector3Array, data: PackedColorArray) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var corners := PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1),
		Vector2(0, 0), Vector2(1, 1), Vector2(0, 1),
	])
	for index: int in range(anchors.size()):
		for corner: Vector2 in corners:
			vertices.append(anchors[index])
			uvs.append(corner)
			colors.append(data[index])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

func _build() -> void:
	var anchors := PackedVector3Array()
	var data := PackedColorArray()
	# Staggered tongues cover both faces of the blade and remain readable at 360°.
	for index: int in range(20):
		var phase: float = float(index) * 0.618034
		var angle: float = phase * TAU
		var along: float = float(index % 10) / 9.0
		anchors.append(Vector3(cos(angle) * 0.066, -0.30 - along * 0.88, sin(angle) * 0.047))
		data.append(Color(fposmod(phase, 1.0), 0.17 + fposmod(phase * 2.7, 0.09),
			0.28 + fposmod(phase * 3.9, 0.21), 0.0))
	for index: int in range(12):
		var phase: float = fposmod(float(index) * 0.618034, 1.0)
		anchors.append(Vector3(sin(phase * TAU) * 0.10, -0.36 - phase * 0.78, cos(phase * TAU) * 0.08))
		data.append(Color(phase, 0.022 + phase * 0.016, 0.07 + phase * 0.045, 1.0))
	_flame_material = flame_material()
	var tongues := MeshInstance3D.new()
	tongues.name = "FlamesAndWhiteSparks"
	tongues.mesh = billboard_mesh(anchors, data)
	tongues.material_override = _flame_material
	tongues.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tongues.custom_aabb = AABB(Vector3(-0.8, -1.5, -0.8), Vector3(1.6, 3.0, 1.6))
	add_child(tongues)
	if not is_instance_valid(_shared_core_shader):
		_shared_core_shader = Shader.new()
		_shared_core_shader.code = CORE_SHADER
	_core_material = ShaderMaterial.new()
	_core_material.shader = _shared_core_shader
	var core := MeshInstance3D.new()
	core.name = "MoltenBladeSheath"
	core.mesh = _core_mesh()
	core.material_override = _core_material
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)

func _core_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var corners: Array[Vector2] = [Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1),
		Vector2(-1, 0), Vector2(1, 1), Vector2(-1, 1)]
	for side: int in range(3):
		var angle: float = float(side) * PI / 3.0
		for corner: Vector2 in corners:
			vertices.append(Vector3(cos(angle) * corner.x * 0.105,
				-0.25 - corner.y * 0.98, sin(angle) * corner.x * 0.105))
			uvs.append(Vector2(corner.x * 0.5 + 0.5, corner.y))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
