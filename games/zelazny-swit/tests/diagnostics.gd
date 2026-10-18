extends SceneTree
## Diagnostics privacy, queue and lifecycle checks; networking is forbidden in isolated mode.
var diagnostics: Node
var diagnostics_script: Script
var checks: int = 0
var failures: int = 0
var directory: String

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _run() -> void:
	var expected_root: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--test-data-root="):
			expected_root = arg.trim_prefix("--test-data-root=").trim_suffix("/")
	if not "--test-isolated" in OS.get_cmdline_user_args() or expected_root.is_empty() or not expected_root.is_absolute_path() or not OS.get_user_data_dir().begins_with(expected_root + "/"):
		push_error("Refusing diagnostics fixtures outside explicit disposable XDG_DATA_HOME/--test-data-root.")
		quit(2)
		return
	diagnostics = root.get_node("Diagnostics")
	diagnostics_script = load("res://scripts/diagnostics.gd")
	diagnostics.set_process(false)
	directory = diagnostics.storage_root()
	_check(diagnostics.is_test_mode() and (directory == "user://diagnostics_test" or directory.begins_with("user://diagnostics_test/")),"isolated diagnostics uses its separate test directory")
	diagnostics.set_enabled(false)
	diagnostics.set_enabled(true)
	var preferences: Dictionary = _read(directory+"/preferences.json")
	var install_id: String = str(preferences.get("install_id",""))
	_check(install_id.length() == 32 and install_id.is_valid_hex_number(false),"installation identifier is a valid random-format opaque identifier")
	_check(preferences.size() == 2 and preferences.has("enabled"),"preferences contain only enabled state and opaque installation identifier")
	_write(directory+"/diagnostics_config.json",{"endpoint":"https://example.invalid/qa","site_bearer_token":"qa-only-secret-token"})
	diagnostics._load_endpoint()
	_check(diagnostics.has_method("is_network_enabled") and not diagnostics.is_network_enabled(),"isolated mode forbids networking even with a configured HTTPS endpoint")
	diagnostics.note("forge_before_upgrade",{"uid":1,"cost":100,"upgrade":0,"save":{"gold":10000},"inventory":["private"],"email":"person@example.test","token":"qa-only-secret-token","detail":"/storage/emulated/0/private.txt person@example.test https://private.invalid token=hiddenvalue"})
	var session: Dictionary = _read(directory+"/session.json")
	var session_text: String = JSON.stringify(session)
	_check(not session.is_empty() and not session.clean and not session.paused,"event breadcrumb is persisted synchronously before returning")
	_check(not session_text.contains("person@example.test") and not session_text.contains("/storage/") and not session_text.contains("private.invalid") and not session_text.contains("hiddenvalue") and not session_text.contains("qa-only-secret-token"),"persisted breadcrumbs redact contact data, paths, URLs and credentials")
	var latest: Dictionary = session.events.back()
	_check(not latest.data.has("save") and not latest.data.has("inventory") and not latest.data.has("email") and not latest.data.has("token") and latest.data.cost == 100,"event payload excludes save, inventory and sensitive fields while retaining gameplay diagnostics")
	for index: int in range(96):
		diagnostics.note("qa_breadcrumb",{"index":index,"detail":"bounded text ".repeat(100)})
	session = _read(directory+"/session.json")
	var events_valid: bool = session.events.size() == diagnostics.MAX_EVENTS
	for event: Dictionary in session.events:
		events_valid = events_valid and JSON.stringify(event).to_utf8_buffer().size() <= 320
	_check(events_valid and session.events.back().data.index == 95,"persisted event history keeps latest 64 bounded breadcrumbs")
	var filtered: Array = diagnostics._error_lines("WARNING: ordinary warning ignored\nERROR: token=hiddenvalue /storage/emulated/0/private.txt person@example.test https://private.invalid\n at: /workspace/private/game.gd:10\nnormal gameplay text")
	var filtered_text: String = JSON.stringify(filtered)
	_check(filtered.size() == 2 and not filtered_text.contains("ordinary warning") and not filtered_text.contains("normal gameplay"),"engine capture retains errors and immediate stack context rather than ordinary log text")
	_check(not filtered_text.contains("hiddenvalue") and not filtered_text.contains("person@example.test") and not filtered_text.contains("/storage/") and not filtered_text.contains("private.invalid") and not filtered_text.contains("/workspace/"),"captured error text redacts credentials, contacts, paths and URLs")
	var many_errors: String = ""
	for index: int in range(40):
		many_errors += "ERROR: sample_%d %s\n" % [index,"x".repeat(250)]
	filtered = diagnostics._error_lines(many_errors)
	var errors_valid: bool = filtered.size() == diagnostics.MAX_ERRORS
	for entry: Dictionary in filtered:
		errors_valid = errors_valid and str(entry.message).length() <= 192
	_check(errors_valid and str(filtered.back().message).contains("sample_39"),"engine error history retains latest 16 messages bounded to 192 characters")
	var tail_path: String = directory+"/qa-engine-tail.log"
	_write_text(tail_path,"ERROR: old_outside_tail\n"+"ordinary log line\n".repeat(5000)+"ERROR: newest_inside_tail\n")
	var tail: String = diagnostics._read_tail(tail_path)
	_check(tail.to_utf8_buffer().size() <= diagnostics.MAX_LOG_TAIL_BYTES and not tail.contains("old_outside_tail") and tail.contains("newest_inside_tail"),"engine capture reads a bounded log tail rather than an entire file")
	_check(diagnostics.queue_report("test"),"enabled diagnostics durably queues a local report")
	var queue: Array = diagnostics._queue_files()
	var report: Dictionary = _read(str(queue.back()))
	_check(report.schema_version == 1 and report.install_id == install_id and report.metadata.isolated_test and not report.metadata.unclean_exit_is_confirmed_crash,"queued schema identifies isolated diagnostics and never labels an unclean exit a confirmed crash")
	var report_text: String = JSON.stringify(report)
	_check(report_text.to_utf8_buffer().size() <= diagnostics.MAX_REPORT_BYTES and not report_text.contains("qa-only-secret-token"),"queued report is size bounded and contains no configured bearer secret")
	for _index: int in range(12):
		diagnostics.queue_report("test")
	queue = diagnostics._queue_files()
	var queue_valid: bool = queue.size() == diagnostics.MAX_QUEUE
	for path: String in queue:
		var file: FileAccess = FileAccess.open(path,FileAccess.READ)
		queue_valid = queue_valid and file != null and file.get_length() <= diagnostics.MAX_REPORT_BYTES
		if file != null:
			file.close()
	_check(queue_valid,"repeated offline reports keep at most eight bounded queue files")
	diagnostics.flush_pending()
	diagnostics._upload_next()
	_check(not diagnostics.is_network_enabled() and diagnostics._inflight.is_empty() and diagnostics._queue_files().size() == diagnostics.MAX_QUEUE,"forcing a flush cannot send or discard isolated queued reports")
	var acknowledgement_path: String = str(diagnostics._queue_files().front())
	var acknowledgement_id: String = str(_read(acknowledgement_path).report_id)
	diagnostics._inflight = acknowledgement_path
	diagnostics._inflight_report_id = acknowledgement_id
	diagnostics._on_request_completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(["Content-Type: text/html"]),"<html>proxy success page</html>".to_utf8_buffer())
	_check(FileAccess.file_exists(acknowledgement_path),"HTML success page cannot acknowledge or delete a diagnostic report")
	diagnostics._inflight = acknowledgement_path
	diagnostics._inflight_report_id = acknowledgement_id
	diagnostics._on_request_completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(["Content-Type: application/json"]),JSON.stringify({"accepted":true,"report_id":"different_report"}).to_utf8_buffer())
	_check(FileAccess.file_exists(acknowledgement_path),"JSON acknowledgement for another report cannot delete the pending report")
	diagnostics._inflight = acknowledgement_path
	diagnostics._inflight_report_id = acknowledgement_id
	diagnostics._on_request_completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(["Content-Type: application/json"]),JSON.stringify({"accepted":false,"report_id":acknowledgement_id}).to_utf8_buffer())
	_check(FileAccess.file_exists(acknowledgement_path),"server rejection preserves report for a later retry")
	diagnostics._inflight = acknowledgement_path
	diagnostics._inflight_report_id = acknowledgement_id
	diagnostics._on_request_completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(["Content-Type: application/json; charset=utf-8"]),JSON.stringify({"accepted":true,"report_id":acknowledgement_id}).to_utf8_buffer())
	_check(not FileAccess.file_exists(acknowledgement_path) and diagnostics._queue_files().size() == diagnostics.MAX_QUEUE-1,"matching accepted JSON acknowledgement removes exactly its report")
	diagnostics.pause()
	session = _read(directory+"/session.json")
	_check(session.paused,"application pause persists a distinct paused session marker")
	diagnostics.resume()
	session = _read(directory+"/session.json")
	_check(not session.paused and not session.clean,"application resume restores an active unclosed session marker")
	diagnostics.mark_clean()
	_check(_read(directory+"/session.json").clean,"normal shutdown explicitly records a clean session")
	diagnostics.set_enabled(false)
	diagnostics.note("disabled_event")
	_check(not diagnostics.queue_report("test") and diagnostics._queue_files().is_empty() and not FileAccess.file_exists(directory+"/session.json"),"opting out removes local reports and session breadcrumbs and suppresses future collection")
	await _reload()
	_check(not diagnostics.is_enabled() and str(_read(directory+"/preferences.json").install_id) == install_id,"opt-out and installation identity survive a fresh diagnostics instance")
	await _previous_session(false,false)
	queue = diagnostics._queue_files()
	report = _read(str(queue.back())) if not queue.is_empty() else {}
	var unconfirmed_marker: bool = false
	for event: Dictionary in report.get("events",[]):
		if event.name == "previous_session_not_closed":
			unconfirmed_marker = event.data.get("cause","") == "unconfirmed"
	_check(queue.size() == 1 and report.get("kind","") == "unclean_exit" and report.get("session_id","") == "qa_previous_session" and unconfirmed_marker,"unclosed foreground session queues one report with an explicitly unconfirmed cause")
	await _previous_session(false,true)
	_check(diagnostics._queue_files().is_empty(),"previous background-paused session is not reported as a crash")
	await _previous_session(true,false)
	_check(diagnostics._queue_files().is_empty(),"previous clean session creates no unclean-exit report")
	diagnostics.set_enabled(false)
	print("DIAGNOSTICS RESULT: %d checks, %d failures; networking disabled; isolated path %s" % [checks,failures,OS.get_user_data_dir()])
	quit(0 if failures == 0 else 1)

func _reload() -> void:
	root.remove_child(diagnostics)
	diagnostics.free()
	diagnostics = diagnostics_script.new()
	diagnostics.name = "Diagnostics"
	root.add_child(diagnostics)
	diagnostics.set_process(false)
	await process_frame

func _previous_session(clean: bool, paused: bool) -> void:
	diagnostics.set_enabled(false)
	diagnostics.set_enabled(true)
	root.remove_child(diagnostics)
	diagnostics.free()
	_write(directory+"/session.json",{"session_id":"qa_previous_session","started_at":"2026-01-01T00:00:00Z","started_unix":0,"clean":clean,"paused":paused,"events":[{"at":"2026-01-01T00:00:00Z","name":"forge_before_upgrade","data":{"uid":1,"cost":100}}],"engine_errors":[]})
	diagnostics = diagnostics_script.new()
	diagnostics.name = "Diagnostics"
	root.add_child(diagnostics)
	diagnostics.set_process(false)
	await process_frame

func _write(path: String, data: Dictionary) -> void:
	_write_text(path,JSON.stringify(data))

func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) == OK and parser.data is Dictionary:
		return parser.data
	return {}
