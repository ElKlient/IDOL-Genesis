class_name CameraPreferences
extends RefCounted
## Camera preferences are independent of the character, inventory and progress save.
## Tests must explicitly opt in to persistence inside their disposable user directory.

const DEFAULT_ZOOM: float = 1.35
const DEFAULT_PITCH: float = 48.0
const DEFAULT_YAW: float = 0.0
const MIN_ZOOM: float = 1.0
const MAX_ZOOM: float = 1.85
const MIN_PITCH: float = 38.0
const MAX_PITCH: float = 65.0
const MIN_YAW: float = -180.0
const MAX_YAW: float = 180.0
const SETTINGS_PATH: String = "user://camera_settings.cfg"
const MAX_FILE_BYTES: int = 4096

var zoom: float = DEFAULT_ZOOM
var pitch: float = DEFAULT_PITCH
var yaw: float = DEFAULT_YAW
var save_enabled: bool = true

func _init() -> void:
	save_enabled = not "--test-isolated" in OS.get_cmdline_user_args()

func reset_defaults() -> void:
	zoom = DEFAULT_ZOOM
	pitch = DEFAULT_PITCH
	yaw = DEFAULT_YAW

func set_values(new_zoom: Variant, new_pitch: Variant, new_yaw: Variant) -> void:
	zoom = _finite_number(new_zoom, DEFAULT_ZOOM, MIN_ZOOM, MAX_ZOOM)
	pitch = _finite_number(new_pitch, DEFAULT_PITCH, MIN_PITCH, MAX_PITCH)
	yaw = _finite_number(new_yaw, DEFAULT_YAW, MIN_YAW, MAX_YAW)

func as_dictionary() -> Dictionary:
	return {"zoom": zoom, "pitch": pitch, "yaw": yaw}

func load_settings() -> void:
	reset_defaults()
	if not save_enabled or not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var size: int = file.get_length()
	if size <= 0 or size > MAX_FILE_BYTES:
		file.close()
		return
	var text: String = file.get_buffer(size).get_string_from_utf8()
	file.close()
	var config := ConfigFile.new()
	if config.parse(text) != OK:
		return
	set_values(
		config.get_value("camera", "zoom", DEFAULT_ZOOM),
		config.get_value("camera", "pitch", DEFAULT_PITCH),
		config.get_value("camera", "yaw", DEFAULT_YAW)
	)

func save_settings() -> bool:
	if not save_enabled:
		return false
	# Public values remain safe even if a caller assigned a non-finite float directly.
	set_values(zoom, pitch, yaw)
	var config := ConfigFile.new()
	config.set_value("camera", "zoom", zoom)
	config.set_value("camera", "pitch", pitch)
	config.set_value("camera", "yaw", yaw)
	var temporary: String = SETTINGS_PATH + ".tmp"
	if config.save(temporary) != OK:
		_remove_temporary(temporary)
		return false
	var file: FileAccess = FileAccess.open(temporary, FileAccess.READ)
	if file == null:
		_remove_temporary(temporary)
		return false
	var valid: bool = file.get_length() > 0 and file.get_length() <= MAX_FILE_BYTES
	file.close()
	if not valid:
		_remove_temporary(temporary)
		return false
	var error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary),
		ProjectSettings.globalize_path(SETTINGS_PATH)
	)
	if error != OK:
		_remove_temporary(temporary)
		return false
	return true

func _finite_number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if not (value is int or value is float):
		return fallback
	var number: float = float(value)
	if not is_finite(number):
		return fallback
	return clampf(number, minimum, maximum)

func _remove_temporary(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
