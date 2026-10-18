class_name FireImpact
extends Node3D
## One bounded, self-disposing ground slam. Cosmetic only; no combat state.

const SwordFireScript = preload("res://scripts/sword_fire_effect.gd")
const DURATION: float = 1.15
const GROUND_SHADER: String = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform float progress = 0.0;
uniform float intensity = 1.0;
uniform bool ring = true;
void fragment() {
	float alpha;
	vec3 color;
	if (ring) {
		float ridge = 1.0 - abs(UV.y * 2.0 - 1.0);
		float teeth = 0.60 + 0.40 * sin(UV.x * 163.36 - progress * 20.0
			+ sin(UV.x * 61.0 + progress * 11.0) * 2.0);
		alpha = pow(max(0.0, ridge), 1.4) * teeth * intensity;
		color = mix(vec3(1.0, 0.035, 0.005), vec3(1.0, 0.84, 0.27), ridge * teeth);
	} else {
		vec2 p = UV * 2.0 - 1.0;
		float radius = length(p);
		float rays = pow(abs(sin(atan(p.y, p.x) * 7.0 + radius * 15.0)), 9.0);
		float flash = pow(max(0.0, 1.0 - radius), 1.6);
		alpha = flash * (0.35 + 0.65 * rays) * intensity;
		color = mix(vec3(1.0, 0.12, 0.005), vec3(1.0, 0.94, 0.61), flash);
	}
	ALBEDO = color;
	ALPHA = alpha;
}
"""

static var _shared_ground_shader: Shader
static var _shared_ring_mesh: ArrayMesh
static var _shared_flash_mesh: QuadMesh
var _age: float = 0.0
var _crown_material: ShaderMaterial
var _ember_material: ShaderMaterial
var _ring_material: ShaderMaterial
var _flash_material: ShaderMaterial
var _ring: MeshInstance3D
var _flash: MeshInstance3D

func _ready() -> void:
	name = "FireImpact"
	_build()
	_update_effect()

func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		set_process(false)
		return
	_update_effect()

func _update_effect() -> void:
	var progress: float = clampf(_age / DURATION, 0.0, 1.0)
	var expansion: float = 1.0 - pow(1.0 - progress, 2.5)
	var radius: float = 0.48 + expansion * 3.45
	var fade: float = (1.0 - smoothstep(0.36, 1.0, progress)) * smoothstep(0.0, 0.035, progress)
	_crown_material.set_shader_parameter("effect_time", _age)
	_crown_material.set_shader_parameter("intensity", fade)
	_crown_material.set_shader_parameter("radial_radius", radius)
	_crown_material.set_shader_parameter("flame_height_scale", 1.0 - progress * 0.65)
	_ember_material.set_shader_parameter("effect_time", _age)
	_ember_material.set_shader_parameter("intensity", 1.0 - smoothstep(0.63, 1.0, progress))
	_ring.scale = Vector3(radius, 1.0, radius)
	_ring_material.set_shader_parameter("progress", progress)
	_ring_material.set_shader_parameter("intensity", fade * 0.90)
	_flash.scale = Vector3.ONE * (0.8 + expansion * 1.8)
	_flash_material.set_shader_parameter("progress", progress)
	_flash_material.set_shader_parameter("intensity", (1.0 - smoothstep(0.05, 0.52, progress)) * 0.92)

func _build() -> void:
	if not is_instance_valid(_shared_ground_shader):
		_shared_ground_shader = Shader.new()
		_shared_ground_shader.code = GROUND_SHADER
	if not is_instance_valid(_shared_ring_mesh):
		_shared_ring_mesh = _ring_mesh()
	if not is_instance_valid(_shared_flash_mesh):
		_shared_flash_mesh = QuadMesh.new()
		_shared_flash_mesh.size = Vector2(2.0, 2.0)
	_ring_material = ShaderMaterial.new()
	_ring_material.shader = _shared_ground_shader
	_ring = _mesh_node("ExpandingFireFront", _shared_ring_mesh, _ring_material)
	_ring.position.y = 0.055
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = _shared_ground_shader
	_flash_material.set_shader_parameter("ring", false)
	_flash = _mesh_node("GroundContactFlash", _shared_flash_mesh, _flash_material)
	_flash.rotation.x = -PI * 0.5
	_flash.position.y = 0.045
	var anchors := PackedVector3Array()
	var data := PackedColorArray()
	for index: int in range(28):
		var phase: float = fposmod(float(index) * 0.618034, 1.0)
		var angle: float = float(index) / 28.0 * TAU
		anchors.append(Vector3(sin(angle), 0.08, cos(angle)))
		data.append(Color(phase, 0.48 + phase * 0.23, 0.64 + phase * 0.67, 0.0))
	_crown_material = SwordFireScript.flame_material()
	var crown: MeshInstance3D = _mesh_node("RisingFlameCrown",
		SwordFireScript.billboard_mesh(anchors, data), _crown_material)
	crown.custom_aabb = AABB(Vector3(-4.5, -0.1, -4.5), Vector3(9.0, 3.4, 9.0))
	anchors = PackedVector3Array()
	data = PackedColorArray()
	for index: int in range(24):
		var phase: float = fposmod(float(index) * 0.618034, 1.0)
		var angle: float = float(index) / 24.0 * TAU
		anchors.append(Vector3(sin(angle) * 0.34, 0.12, cos(angle) * 0.34))
		data.append(Color(phase, 0.028 + phase * 0.027, 0.12 + phase * 0.14, 1.0))
	_ember_material = SwordFireScript.flame_material()
	_ember_material.set_shader_parameter("burst", true)
	_ember_material.set_shader_parameter("spark_speed", 0.86)
	_ember_material.set_shader_parameter("spark_spread", 3.15)
	_ember_material.set_shader_parameter("spark_rise", 2.0)
	var embers: MeshInstance3D = _mesh_node("WhiteHotEmberBurst",
		SwordFireScript.billboard_mesh(anchors, data), _ember_material)
	embers.custom_aabb = AABB(Vector3(-4.0, -0.1, -4.0), Vector3(8.0, 3.4, 8.0))

func _mesh_node(node_name: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _ring_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	for index: int in range(80):
		var a: float = float(index) / 80.0 * TAU
		var b: float = float(index + 1) / 80.0 * TAU
		var inner_a := Vector3(sin(a) * 0.88, 0, cos(a) * 0.88)
		var outer_a := Vector3(sin(a), 0, cos(a))
		var inner_b := Vector3(sin(b) * 0.88, 0, cos(b) * 0.88)
		var outer_b := Vector3(sin(b), 0, cos(b))
		vertices.append_array(PackedVector3Array([inner_a, outer_a, outer_b, inner_a, outer_b, inner_b]))
		var u_a: float = float(index) / 80.0
		var u_b: float = float(index + 1) / 80.0
		uvs.append_array(PackedVector2Array([Vector2(u_a, 0), Vector2(u_a, 1), Vector2(u_b, 1),
			Vector2(u_a, 0), Vector2(u_b, 1), Vector2(u_b, 0)]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
