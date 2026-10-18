extends Node
## Bounded, asynchronous diagnostics. No save files, account data or hardware IDs.
## A previous unclosed foreground session is a clue, never a confirmed native crash.
signal status_changed

const SCHEMA_VERSION: int = 1
const PRODUCTION_ENDPOINT: String = "https://zelazny-swit-diagnostyka.sethoyt.chatgpt.site/api/reports"
const MAX_EVENTS: int = 64
const MAX_ERRORS: int = 16
const MAX_REPORT_BYTES: int = 32768
const MAX_QUEUE: int = 8
const MAX_LOG_TAIL_BYTES: int = 32768
const HEARTBEAT_SECONDS: float = 60.0
const CHECKPOINT_SECONDS: float = 300.0
const FORGE_THROTTLE_MSEC: int = 15000
const ERROR_THROTTLE_MSEC: int = 30000
const BLOCKED_DATA_KEYS: Array[String] = ["save", "inventory", "email", "name", "path", "url", "token", "bearer", "secret", "password", "ip", "address", "device_id", "android_id", "user", "account"]

var _enabled: bool = true
var _started: bool = false
var _test_mode: bool = false
var _network_test_mode: bool = false
var _storage_failed: bool = false
var _paused: bool = false
var _clean: bool = false
var _directory: String = "user://diagnostics"
var _install_id: String = ""
var _session_id: String = ""
var _started_at: String = ""
var _started_unix: int = 0
var _events: Array[Dictionary] = []
var _engine_errors: Array[Dictionary] = []
var _seen_errors: Array[String] = []
var _endpoint: String = ""
var _bearer: String = ""
var _http: HTTPRequest
var _inflight: String = ""
var _inflight_report_id: String = ""
var _failure_count: int = 0
var _next_attempt_msec: int = 0
var _last_result: String = ""
var _heartbeat_elapsed: float = 0.0
var _checkpoint_elapsed: float = 0.0
var _log_elapsed: float = 0.0
var _last_log_length: int = 0
var _last_forge_msec: int = -FORGE_THROTTLE_MSEC
var _forge_due_msec: int = 0
var _forge_pending: bool = false
var _last_error_report_msec: int = -ERROR_THROTTLE_MSEC
var _error_report_pending: bool = false
var _path_regex := RegEx.new()
var _email_regex := RegEx.new()
var _url_regex := RegEx.new()
var _secret_regex := RegEx.new()
var _event_name_regex := RegEx.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_test_mode = "--test-isolated" in OS.get_cmdline_user_args()
	_network_test_mode = "--diagnostics-network-test" in OS.get_cmdline_user_args()
	if _test_mode:
		_directory = "user://diagnostics_test/" + _isolated_test_id()
	elif _network_test_mode:
		_directory = "user://diagnostics_network_test"
	_compile_redaction()
	_prepare_directory()
	_load_preferences()
	_load_endpoint()
	_session_id = _random_id()
	_started_at = _timestamp()
	_started_unix = int(Time.get_unix_time_from_system())
	_http = HTTPRequest.new()
	# Allow mobile/proxied TLS handshakes without blocking gameplay. Five seconds
	# proved too short in the real HTTPS smoke test; the bounded retry stays async.
	_http.timeout = 15.0
	_http.body_size_limit = 8192
	_http.max_redirects = 0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_started = true
	if _enabled:
		_recover_previous_session()
		note("session_started", {"isolated_test": _test_mode})
		if is_network_enabled():
			_checkpoint_elapsed = CHECKPOINT_SECONDS - 3.0
	else:
		_purge_diagnostics()
	status_changed.emit()

func _compile_redaction() -> void:
	_path_regex.compile("(?:[A-Za-z]:[\\\\/]|/(?:home|Users|data|storage|sdcard|workspace|root)/)[^\\s\"'<>]*")
	_email_regex.compile("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
	_url_regex.compile("https?://[^\\s\"'<>]+")
	_secret_regex.compile("(?i)(?:bearer|token|api[_ -]?key|password|secret)[=: ]+[^\\s,;]+")
	_event_name_regex.compile("[^a-zA-Z0-9_.:-]")

func _isolated_test_id() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--diagnostics-test-id="):
			continue
		var value: String = arg.trim_prefix("--diagnostics-test-id=")
		var valid: bool = not value.is_empty() and value.length() <= 48
		for i: int in range(value.length()):
			var code: int = value.unicode_at(i)
			if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 45 or code == 95):
				valid = false
		if valid:
			return value
	return str(OS.get_process_id())

func storage_root() -> String:
	return _directory

func is_enabled() -> bool:
	return _enabled

func is_test_mode() -> bool:
	return _test_mode

func is_network_enabled() -> bool:
	return _enabled and not _test_mode and not _paused and _endpoint_allowed(_endpoint) and not _bearer.is_empty()

func set_enabled(value: bool) -> void:
	if _enabled == value:
		return
	_enabled = value
	if not value:
		if is_instance_valid(_http):
			_http.cancel_request()
		_inflight = ""
		_inflight_report_id = ""
		_events.clear()
		_engine_errors.clear()
		_seen_errors.clear()
		_forge_pending = false
		_error_report_pending = false
		_purge_diagnostics()
		_last_result = ""
	else:
		_clean = false
		_paused = false
		note("diagnostics_enabled")
	_save_preferences()
	status_changed.emit()

func note(event_name: String, data: Dictionary = {}) -> void:
	if not _enabled or not _started:
		return
	var safe_name: String = _event_name_regex.sub(event_name, "_", true).left(64)
	if safe_name.is_empty():
		safe_name = "event"
	var event: Dictionary = {"at": _timestamp(), "name": safe_name, "data": _sanitize_data(data)}
	while JSON.stringify(event).to_utf8_buffer().size() > 320 and not event.data.is_empty():
		var keys: Array = event.data.keys()
		event.data.erase(keys.back())
	_events.append(event)
	while _events.size() > MAX_EVENTS:
		_events.pop_front()
	_clean = false
	# This small atomic write happens before note() returns, including before forging.
	_persist_session()
	if safe_name.begins_with("forge_"):
		_forge_pending = true
		_forge_due_msec = Time.get_ticks_msec() + 650

func queue_report(kind: String = "checkpoint") -> bool:
	if not _enabled or not _started:
		return false
	var allowed: Array[String] = ["unclean_exit", "engine_error", "checkpoint", "test"]
	if kind not in allowed:
		kind = "checkpoint"
	var success: bool = _enqueue_report(kind, _session_id, _events, _engine_errors)
	if success:
		status_changed.emit()
	return success

func flush_pending() -> void:
	_next_attempt_msec = 0

func mark_clean() -> void:
	if not _enabled or not _started:
		return
	_clean = true
	_persist_session()

func pause() -> void:
	if not _enabled or not _started:
		return
	_paused = true
	_persist_session()

func resume() -> void:
	if not _enabled or not _started:
		return
	_paused = false
	_clean = false
	_persist_session()

func status_text() -> String:
	if not _enabled:
		return "Raporty wyłączone · nie zapisano ustawienia" if _storage_failed else "Raporty wyłączone"
	if _test_mode:
		return "Test izolowany · wysyłanie wyłączone"
	if not _endpoint_allowed(_endpoint):
		return "Raporty lokalne · brak konfiguracji serwera"
	if _bearer.is_empty():
		return "Aktywuj raporty: pobierz konfigurację"
	if _storage_failed:
		return "Raporty wstrzymane · brak miejsca na zapis"
	if not _inflight.is_empty():
		return "Wysyłanie raportu w tle…"
	var count: int = _queue_files().size()
	if count > 0:
		return "Raporty oczekujące: %d · ponawianie w tle" % count
	if _last_result == "sent":
		return "Raport wysłany · diagnostyka aktywna"
	return "Diagnostyka aktywna · gotowa"

func _notification(what: int) -> void:
	if not _started:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		pause()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		resume()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		mark_clean()

func _exit_tree() -> void:
	if is_instance_valid(_http):
		_http.cancel_request()
	mark_clean()

func _process(delta: float) -> void:
	if not _enabled or not _started or _paused:
		return
	var now: int = Time.get_ticks_msec()
	_heartbeat_elapsed += delta
	_checkpoint_elapsed += delta
	_log_elapsed += delta
	if _heartbeat_elapsed >= HEARTBEAT_SECONDS:
		_heartbeat_elapsed = 0.0
		_persist_session()
	if _checkpoint_elapsed >= CHECKPOINT_SECONDS:
		_checkpoint_elapsed = 0.0
		if _queue_files().is_empty():
			queue_report("checkpoint")
	if _forge_pending and now >= _forge_due_msec and now - _last_forge_msec >= FORGE_THROTTLE_MSEC:
		_forge_pending = false
		_last_forge_msec = now
		queue_report("checkpoint")
	if _log_elapsed >= 10.0:
		_log_elapsed = 0.0
		_poll_engine_log()
	if _error_report_pending and now - _last_error_report_msec >= ERROR_THROTTLE_MSEC:
		_error_report_pending = false
		_last_error_report_msec = now
		queue_report("engine_error")
	if _inflight.is_empty() and now >= _next_attempt_msec:
		_upload_next()

func _prepare_directory() -> void:
	_storage_failed = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_directory + "/queue")) != OK
	# Only our own interrupted atomic writes are disposable.
	for directory: String in [_directory, _directory + "/queue"]:
		var handle: DirAccess = DirAccess.open(directory)
		if handle == null:
			continue
		for file: String in handle.get_files():
			if file.ends_with(".tmp"):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(directory + "/" + file))

func _load_preferences() -> void:
	var prefs: Dictionary = _read_json(_directory + "/preferences.json", 4096)
	_enabled = bool(prefs.get("enabled", true))
	_install_id = str(prefs.get("install_id", ""))
	if _install_id.length() != 32 or not _install_id.is_valid_hex_number(false):
		_install_id = _random_id()
	_save_preferences()

func _save_preferences() -> void:
	_write_json(_directory + "/preferences.json", {"enabled": _enabled, "install_id": _install_id})

func _load_endpoint() -> void:
	var config: Dictionary = _read_json("res://diagnostics_config.json", 8192)
	# Private export-side config is gitignored; public project config never supplies a token.
	var local: Dictionary = _read_json("res://diagnostics.local.json", 8192)
	config.merge(local, true)
	var override_path: String = _directory + "/diagnostics_config.json" if _test_mode else "user://diagnostics_config.json"
	var override: Dictionary = _read_json(override_path, 8192)
	config.merge(override, true)
	_endpoint = str(config.get("endpoint", "")).strip_edges()
	_bearer = str(override.get("site_bearer_token", local.get("site_bearer_token", ""))).strip_edges()
	if _endpoint != PRODUCTION_ENDPOINT or _bearer.contains("\n") or _bearer.contains("\r") or _bearer.length() > 2048:
		_bearer = ""

func _recover_previous_session() -> void:
	var previous: Dictionary = _read_json(_directory + "/session.json", MAX_REPORT_BYTES)
	if previous.is_empty() or bool(previous.get("clean", true)) or bool(previous.get("paused", false)):
		return
	var previous_events: Array[Dictionary] = _bounded_events(previous.get("events", []))
	previous_events.append({"at": _timestamp(), "name": "previous_session_not_closed", "data": {"cause": "unconfirmed"}})
	while previous_events.size() > MAX_EVENTS:
		previous_events.pop_front()
	var previous_errors: Array[Dictionary] = _bounded_errors(previous.get("engine_errors", []))
	# Rotated engine logs are read only inside this game's user directory, at most 32 KiB.
	var raw_start: Variant = previous.get("started_unix", 0)
	var previous_start: int = 0
	if raw_start is int:
		previous_start = maxi(0, int(raw_start))
	elif raw_start is float and is_finite(float(raw_start)):
		previous_start = maxi(0, int(raw_start))
	var candidate: String = _latest_rotated_log(previous_start)
	if not candidate.is_empty():
		for entry: Dictionary in _error_lines(_read_tail(candidate)):
			previous_errors.append(entry)
	while previous_errors.size() > MAX_ERRORS:
		previous_errors.pop_front()
	_enqueue_report("unclean_exit", str(previous.get("session_id", "unknown")).left(64), previous_events, previous_errors)

func _persist_session() -> void:
	if not _enabled or not _started:
		return
	var session: Dictionary = {
		"session_id": _session_id, "started_at": _started_at, "started_unix": _started_unix,
		"last_seen_at": _timestamp(), "clean": _clean, "paused": _paused,
		"events": _events.duplicate(true), "engine_errors": _engine_errors.duplicate(true)
	}
	while JSON.stringify(session).to_utf8_buffer().size() > MAX_REPORT_BYTES:
		if not session.events.is_empty():
			session.events.pop_front()
		elif not session.engine_errors.is_empty():
			session.engine_errors.pop_front()
		else:
			return
	_write_json(_directory + "/session.json", session)

func _enqueue_report(kind: String, session_id: String, events: Array[Dictionary], errors: Array[Dictionary]) -> bool:
	var report_id: String = _random_id()
	var report: Dictionary = {
		"schema_version": SCHEMA_VERSION, "report_id": report_id,
		"install_id": _install_id, "session_id": session_id,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "unknown")),
		"kind": kind, "created_at": _timestamp(), "metadata": _metadata(),
		"events": _bounded_events(events), "engine_errors": _bounded_errors(errors)
	}
	while JSON.stringify(report).to_utf8_buffer().size() > MAX_REPORT_BYTES:
		if not report.events.is_empty():
			report.events.pop_front()
		elif not report.engine_errors.is_empty():
			report.engine_errors.pop_front()
		else:
			return false
	# Bound disk before and after writing, including repeated failed connections.
	var files: Array[String] = _queue_files()
	while files.size() >= MAX_QUEUE:
		var oldest: String = files.pop_front()
		if oldest == _inflight:
			files.append(oldest)
			if files.size() == 1:
				break
			continue
		DirAccess.remove_absolute(ProjectSettings.globalize_path(oldest))
	var path: String = _directory + "/queue/report_%020d_%s.json" % [int(Time.get_unix_time_from_system() * 1000000.0), report_id]
	return _write_json(path, report)

func _metadata() -> Dictionary:
	return {
		"godot_version": str(Engine.get_version_info().get("string", "unknown")),
		"os": OS.get_name(), "architecture": Engine.get_architecture_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"debug_build": OS.is_debug_build(), "isolated_test": _test_mode, "network_test": _network_test_mode,
		"error_capture": "bounded_engine_log_tail", "unclean_exit_is_confirmed_crash": false
	}

func _queue_files() -> Array[String]:
	var result: Array[String] = []
	var dir: DirAccess = DirAccess.open(_directory + "/queue")
	if dir == null:
		return result
	for file: String in dir.get_files():
		if file.begins_with("report_") and file.ends_with(".json"):
			result.append(_directory + "/queue/" + file)
	result.sort()
	return result

func _endpoint_allowed(endpoint: String) -> bool:
	if endpoint.is_empty() or endpoint.contains("@") or endpoint.contains("\n") or endpoint.contains("\r") or endpoint.contains(" "):
		return false
	if endpoint == PRODUCTION_ENDPOINT:
		return true
	return _test_mode and "--diagnostics-allow-http-test" in OS.get_cmdline_user_args() and endpoint.to_lower().begins_with("http://")

func _upload_next() -> void:
	# Isolated tests can exercise the queue but can never send a packet.
	if not is_network_enabled():
		_next_attempt_msec = Time.get_ticks_msec() + 10000
		return
	var files: Array[String] = _queue_files()
	if files.is_empty():
		_next_attempt_msec = Time.get_ticks_msec() + 5000
		return
	var path: String = files.front()
	var payload: Dictionary = _read_json(path, MAX_REPORT_BYTES)
	if payload.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		_next_attempt_msec = Time.get_ticks_msec() + 2000
		return
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if not _bearer.is_empty():
		headers.append("OAI-Sites-Authorization: Bearer " + _bearer)
	_inflight = path
	_inflight_report_id = str(payload.get("report_id", ""))
	var result: Error = _http.request(_endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if result != OK:
		_inflight = ""
		_inflight_report_id = ""
		_backoff()
	status_changed.emit()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if _inflight.is_empty():
		return
	var acknowledged: bool = false
	var json_content: bool = false
	for header: String in headers:
		if header.get_slice(":", 0).strip_edges().to_lower() == "content-type" and header.get_slice(":", 1).strip_edges().to_lower().begins_with("application/json"):
			json_content = true
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and json_content and body.size() <= 8192:
		var parser := JSON.new()
		if parser.parse(body.get_string_from_utf8()) == OK and parser.data is Dictionary:
			var response: Dictionary = parser.data
			var accepted: Variant = response.get("accepted", false)
			acknowledged = accepted is bool and accepted and str(response.get("report_id", "")) == _inflight_report_id and not _inflight_report_id.is_empty()
	if acknowledged:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_inflight))
		_failure_count = 0
		_next_attempt_msec = Time.get_ticks_msec() + 2000
		_last_result = "sent"
	else:
		_backoff()
	_inflight = ""
	_inflight_report_id = ""
	status_changed.emit()

func _backoff() -> void:
	_failure_count = mini(_failure_count + 1, 6)
	var delays: Array[int] = [5, 15, 45, 120, 300, 300]
	_next_attempt_msec = Time.get_ticks_msec() + delays[_failure_count - 1] * 1000
	_last_result = "waiting"

func _poll_engine_log() -> void:
	var path: String = "user://logs/godot.log"
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var length: int = file.get_length()
	if length == _last_log_length:
		file.close()
		return
	var start: int = maxi(_last_log_length, length - MAX_LOG_TAIL_BYTES) if length >= _last_log_length else maxi(0, length - MAX_LOG_TAIL_BYTES)
	file.seek(start)
	var raw: PackedByteArray = file.get_buffer(mini(MAX_LOG_TAIL_BYTES, length - start))
	file.close()
	if start > _last_log_length:
		var newline: int = raw.find(10)
		if newline >= 0:
			raw = raw.slice(newline + 1)
		else:
			raw = PackedByteArray()
	var chunk: String = raw.get_string_from_utf8()
	_last_log_length = length
	var changed: bool = false
	for entry: Dictionary in _error_lines(chunk):
		var message: String = str(entry.message)
		if message in _seen_errors:
			continue
		_seen_errors.append(message)
		while _seen_errors.size() > 32:
			_seen_errors.pop_front()
		_engine_errors.append(entry)
		while _engine_errors.size() > MAX_ERRORS:
			_engine_errors.pop_front()
		changed = true
	if changed:
		_persist_session()
		_error_report_pending = true

func _error_lines(text: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var context: int = 0
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		var is_error: bool = line.contains("ERROR:") or line.contains("SCRIPT ERROR") or line.contains("Parse Error:") or line.contains("CRASH HANDLER") or line.contains("FATAL:")
		if is_error:
			context = 2
		elif context > 0 and (line.begins_with("at:") or line.begins_with("GDScript backtrace") or line.begins_with("[0]")):
			context -= 1
		else:
			context = 0
			continue
		result.append({"at": _timestamp(), "message": _redact_text(line).left(192)})
		while result.size() > MAX_ERRORS:
			result.pop_front()
	return result

func _latest_rotated_log(start_unix: int) -> String:
	var dir: DirAccess = DirAccess.open("user://logs")
	if dir == null:
		return ""
	var selected: String = ""
	var latest: int = 0
	for file: String in dir.get_files():
		if not file.begins_with("godot") or not file.ends_with(".log") or file == "godot.log":
			continue
		var path: String = "user://logs/" + file
		var modified: int = FileAccess.get_modified_time(path)
		if modified >= start_unix - 5 and modified > latest:
			selected = path
			latest = modified
	return selected

func _read_tail(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var length: int = file.get_length()
	var offset: int = maxi(0, length - MAX_LOG_TAIL_BYTES)
	file.seek(offset)
	var raw: PackedByteArray = file.get_buffer(mini(length, MAX_LOG_TAIL_BYTES))
	file.close()
	if offset > 0:
		var newline: int = raw.find(10)
		if newline >= 0:
			raw = raw.slice(newline + 1)
		else:
			raw = PackedByteArray()
	return raw.get_string_from_utf8()

func _bounded_events(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array:
		return result
	var source: Array = value
	for i: int in range(maxi(0, source.size() - MAX_EVENTS), source.size()):
		if not source[i] is Dictionary:
			continue
		var entry: Dictionary = source[i]
		var event: Dictionary = {"at": str(entry.get("at", "")).left(32), "name": _event_name_regex.sub(str(entry.get("name", "event")), "_", true).left(64), "data": _sanitize_data(entry.get("data", {}))}
		while JSON.stringify(event).to_utf8_buffer().size() > 320 and not event.data.is_empty():
			var keys: Array = event.data.keys()
			event.data.erase(keys.back())
		result.append(event)
	return result

func _bounded_errors(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array:
		return result
	var source: Array = value
	for i: int in range(maxi(0, source.size() - MAX_ERRORS), source.size()):
		if source[i] is Dictionary:
			var entry: Dictionary = source[i]
			result.append({"at": str(entry.get("at", "")).left(32), "message": _redact_text(str(entry.get("message", ""))).left(192)})
	return result

func _sanitize_data(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result
	var source: Dictionary = value
	for raw_key: Variant in source:
		if result.size() >= 8:
			break
		var key: String = str(raw_key).left(24)
		var lowered: String = key.to_lower()
		var blocked: bool = false
		for token: String in BLOCKED_DATA_KEYS:
			if lowered == token or lowered.begins_with(token + "_") or lowered.ends_with("_" + token):
				blocked = true
		if blocked:
			continue
		var item: Variant = source[raw_key]
		if item is bool or item is int:
			result[key] = item
		elif item is float:
			if is_finite(float(item)):
				result[key] = item
		elif item is String:
			result[key] = _redact_text(str(item)).left(64)
	return result

func _redact_text(value: String) -> String:
	var result: String = value.replace(OS.get_user_data_dir(), "[user_data]")
	if not _bearer.is_empty():
		result = result.replace(_bearer, "[credential]")
	result = _path_regex.sub(result, "[path]", true)
	result = _email_regex.sub(result, "[email]", true)
	result = _url_regex.sub(result, "[url]", true)
	result = _secret_regex.sub(result, "[credential]", true)
	return result

func _purge_diagnostics() -> void:
	for path: String in _queue_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var session: String = _directory + "/session.json"
	if FileAccess.file_exists(session):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(session))

func _read_json(path: String, max_bytes: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	if file.get_length() > max_bytes:
		file.close()
		return {}
	var text: String = file.get_buffer(max_bytes).get_string_from_utf8()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return {}
	return parser.data

func _write_json(path: String, value: Dictionary) -> bool:
	if _storage_failed:
		return false
	var text: String = JSON.stringify(value)
	if text.to_utf8_buffer().size() > MAX_REPORT_BYTES:
		return false
	var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		_storage_failed = true
		return false
	file.store_string(text)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		_storage_failed = true
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".tmp"))
		return false
	var from: String = ProjectSettings.globalize_path(path + ".tmp")
	var to: String = ProjectSettings.globalize_path(path)
	var error: Error = DirAccess.rename_absolute(from, to)
	if error != OK:
		_storage_failed = true
		DirAccess.remove_absolute(from)
		return false
	return true

func _random_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

func _timestamp() -> String:
	return Time.get_datetime_string_from_system(true, false) + "Z"
