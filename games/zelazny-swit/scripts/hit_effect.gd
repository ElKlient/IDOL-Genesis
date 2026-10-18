class_name HitEffect
extends Node3D
## A reusable contact, not a screen filter: three tiny batches, no textures,
## lights, physics or per-spark nodes. World-space placement survives knockback.
const MAX_ACTIVE: int = 8
const LIFETIME: float = 0.38
const SPARK_COUNT: int = 12
const DUST_COUNT: int = 5
static var active_count: int = 0
static var _spark_mesh: ArrayMesh
static var _dust_mesh: ArrayMesh
static var _flash_mesh: QuadMesh
static var _solid_material: StandardMaterial3D
static var _flash_material: StandardMaterial3D
static var _dust_material: ShaderMaterial

var running: bool = false
var elapsed: float = 0.0
var _heavy: bool = false
var _critical: bool = false
var _stone: bool = false
var _height: float = 0.8
var _flash: MultiMeshInstance3D
var _sparks: MultiMeshInstance3D
var _dust: MultiMeshInstance3D
var _directions: PackedVector3Array = PackedVector3Array()
var _speeds: PackedFloat32Array = PackedFloat32Array()

func _ready() -> void:
	set_as_top_level(true)
	_build_shared_resources()
	_flash = _batch(_flash_mesh,_flash_material,2)
	_sparks = _batch(_spark_mesh,_solid_material,SPARK_COUNT)
	_dust = _batch(_dust_mesh,_dust_material,DUST_COUNT)
	visible = false
	set_process(false)

func _build_shared_resources() -> void:
	if _spark_mesh != null:
		return
	_solid_material = StandardMaterial3D.new()
	_solid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_solid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_solid_material.vertex_color_use_as_albedo = true
	_solid_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_solid_material.no_depth_test = false
	_flash_material = _solid_material.duplicate() as StandardMaterial3D
	_flash_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var dust_shader := Shader.new()
	dust_shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
    float edge = 1.0 - smoothstep(0.12, 0.49, length(UV - vec2(0.5)));
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a * edge;
}
"""
	_dust_material = ShaderMaterial.new()
	_dust_material.shader = dust_shader
	_flash_mesh = QuadMesh.new()
	_flash_mesh.size = Vector2.ONE
	# A narrow double-ended shard, rather than a large glowing box.
	var vertices := PackedVector3Array([
		Vector3(0,0,-0.5),Vector3(-0.15,0,0),Vector3(0,0.10,0),
		Vector3(0,0,-0.5),Vector3(0,0.10,0),Vector3(0.15,0,0),
		Vector3(0,0,0.5),Vector3(0,0.10,0),Vector3(-0.15,0,0),
		Vector3(0,0,0.5),Vector3(0.15,0,0),Vector3(0,0.10,0)])
	_spark_mesh = _mesh(vertices)
	vertices = PackedVector3Array()
	for i: int in range(9):
		var a: float = TAU * float(i) / 9.0
		var b: float = TAU * float(i+1) / 9.0
		vertices.append(Vector3.ZERO)
		vertices.append(Vector3(cos(a),0,sin(a))*0.5)
		vertices.append(Vector3(cos(b),0,sin(b))*0.5)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var uv := PackedVector2Array()
	for vertex: Vector3 in vertices:
		uv.append(Vector2(vertex.x+0.5,vertex.z+0.5))
	arrays[Mesh.ARRAY_TEX_UV] = uv
	_dust_mesh = ArrayMesh.new()
	_dust_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)

func _mesh(vertices: PackedVector3Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _batch(mesh: Mesh,material: Material,count: int) -> MultiMeshInstance3D:
	var batch := MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = mesh
	instances.instance_count = count
	batch.multimesh = instances
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.custom_aabb = AABB(Vector3(-2,-2,-2),Vector3(4,4,4))
	add_child(batch)
	return batch

func trigger(point: Vector3,direction: Vector3,heavy: bool = false,critical: bool = false,stone: bool = false,contact_height: float = 0.8) -> bool:
	if not is_inside_tree() or not point.is_finite() or not direction.is_finite() or not is_finite(contact_height):
		return false
	if not running and active_count >= MAX_ACTIVE:
		return false
	if not running:
		active_count += 1
	running = true
	elapsed = 0.0
	_heavy = heavy
	_critical = critical
	_stone = stone
	_height = clampf(contact_height,0.3,2.5)
	global_position = point
	var flat := Vector3(direction.x,0,direction.z)
	rotation = Vector3(0,atan2(flat.x,flat.z),0) if flat.length_squared()>0.0001 else Vector3.ZERO
	_directions.clear()
	_speeds.clear()
	# The same bounded fan is rotated with the actual strike direction.
	# No per-frame RNG, particle simulation or resource allocation is required.
	for i: int in range(SPARK_COUNT):
		var angle: float = TAU * float(i) / SPARK_COUNT
		var spread: float = 0.30 + float(i % 4) * 0.16
		_directions.append(Vector3(cos(angle)*spread,0.25+float(i%3)*0.22,0.65+sin(angle)*spread).normalized())
		_speeds.append((1.8+float(i%4)*0.32)*(1.2 if heavy else 1.0))
	visible = true
	set_process(true)
	_update_batches()
	return true

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += maxf(delta,0.0)
	if elapsed >= LIFETIME:
		stop()
		return
	_update_batches()

func _update_batches() -> void:
	var t: float = elapsed
	var fade: float = clampf(1.0-t/LIFETIME,0.0,1.0)
	var intensity: float = 1.20 if _heavy or _critical else 1.0
	var flash_fade: float = pow(clampf(1.0-t/(0.11 if _heavy else 0.085),0.0,1.0),1.4)
	for i: int in range(2):
		var line_scale := Vector3((0.43 if i==0 else 0.15)*intensity,(0.038 if i==0 else 0.030)*intensity,1)
		var line_basis := Basis(Vector3.FORWARD,-0.62 if i==0 else 0.95).scaled(line_scale)
		_flash.multimesh.set_instance_transform(i,Transform3D(line_basis,Vector3(0,0,-0.06)))
		_flash.multimesh.set_instance_color(i,Color(1.0,0.94,0.77,flash_fade*0.9))
	var sparks: int = SPARK_COUNT if _heavy or _critical else 8
	_sparks.multimesh.visible_instance_count = sparks
	for i: int in range(sparks):
		var drift: Vector3 = _directions[i] * _speeds[i] * t
		drift.y -= 3.6*t*t
		var length: float = (0.13+float(i%3)*0.035)*fade*(1.0 if _stone else 0.75)
		var transform := Transform3D(Basis(Quaternion(Vector3.FORWARD,_directions[i])).scaled(Vector3(0.050*fade,0.050*fade,length)),drift)
		_sparks.multimesh.set_instance_transform(i,transform)
		var color := Color(1.0,0.75+float(i%3)*0.08,0.30,fade) if _stone else Color(0.86,0.78,0.62,fade*0.78)
		if _stone and i%3==0:
			color = Color(0.76,0.75,0.65,fade*0.88)
		if _critical and i<2:
			color = Color(1.0,0.96,0.82,fade)
		_sparks.multimesh.set_instance_color(i,color)
	for i: int in range(DUST_COUNT):
		var angle: float = TAU*float(i)/DUST_COUNT+0.25
		var travel: float = t*(0.55 if _heavy else 0.35)
		var center := Vector3(cos(angle)*travel,0.03-_height+float(i)*0.002,sin(angle)*travel)
		var size: float = (0.13+t*0.65)*(1.25 if _heavy else 1.0)
		_dust.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(size,1,size)),center))
		_dust.multimesh.set_instance_color(i,Color(0.48,0.43,0.34,fade*fade*0.16))

func stop() -> void:
	if running:
		active_count = maxi(0,active_count-1)
	running = false
	visible = false
	set_process(false)

func _exit_tree() -> void:
	stop()
