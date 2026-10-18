extends SceneTree
## Explicit live smoke test. Root must inject private config into a disposable
## XDG_DATA_HOME's user://diagnostics_config.json before starting Godot.
## Never pass credentials as command-line arguments or print response bodies.
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
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var expected_root: String = ""
	for arg: String in args:
		if arg.begins_with("--test-data-root="):
			expected_root = arg.trim_prefix("--test-data-root=").trim_suffix("/")
	if not "--diagnostics-network-test" in args or "--test-isolated" in args or expected_root.is_empty() or not expected_root.is_absolute_path() or not OS.get_user_data_dir().begins_with(expected_root + "/"):
		push_error("Refusing live diagnostics outside explicit disposable XDG_DATA_HOME/--test-data-root and --diagnostics-network-test mode.")
		quit(2)
		return
	var state: Node = root.get_node("GameState")
	state.save_enabled = false
	var save_existed: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_existed else PackedByteArray()
	var diagnostics: Node = root.get_node("Diagnostics")
	# Managed QA may require a local HTTPS CONNECT proxy. This applies only to
	# this explicitly opted-in test, never the phone's production configuration.
	for arg: String in args:
		if arg.begins_with("--test-https-proxy="):
			var proxy: String = arg.trim_prefix("--test-https-proxy=")
			var request: HTTPRequest = diagnostics.get("_http")
			request.set_https_proxy(proxy.get_slice(":",0),int(proxy.get_slice(":",1)))
	directory = diagnostics.storage_root()
	_check(directory == "user://diagnostics_network_test" and not diagnostics.is_test_mode(),"explicit network smoke uses a separate disposable diagnostics directory")
	_check(diagnostics.is_enabled() and diagnostics.is_network_enabled(),"private local configuration enables the authorized HTTPS smoke test")
	if failures > 0:
		print("DIAGNOSTICS NETWORK RESULT: %d checks, %d failures; configuration unavailable" % [checks,failures])
		quit(1)
		return
	_check(_queue_files().is_empty(),"disposable network smoke starts with no unrelated reports")
	diagnostics.note("network_probe",{"origin":"godot_smoke_test","network_test":true})
	_check(diagnostics.queue_report("test"),"actual Godot client queues the authorized test report")
	var files: Array[String] = _queue_files()
	var report_id: String = ""
	if not files.is_empty():
		var parser: JSON = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(files.back())) == OK and parser.data is Dictionary:
			report_id = str(parser.data.get("report_id",""))
	_check(report_id.length() == 32 and report_id.is_valid_hex_number(false),"queued live smoke report has a verifiable opaque report identifier")
	diagnostics.flush_pending()
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec()-started < 20000 and not _queue_files().is_empty():
		await create_timer(0.1).timeout
	_check(_queue_files().is_empty(),"actual HTTPS request acknowledges and removes the queued report within twenty seconds")
	_check(diagnostics.status_text().contains("Raport wysłany"),"Godot diagnostics exposes confirmed sent status after server acknowledgement")
	_check(not state.save_enabled and FileAccess.file_exists(state.SAVE_PATH) == save_existed and (not save_existed or FileAccess.get_file_as_bytes(state.SAVE_PATH) == save_before),"live diagnostics smoke does not change the disposable game save")
	diagnostics.mark_clean()
	if not report_id.is_empty():
		# This random ID is safe to compare with the backend record; no auth or body is logged.
		print("DIAGNOSTICS NETWORK REPORT ID: " + report_id)
	print("DIAGNOSTICS NETWORK RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _queue_files() -> Array[String]:
	var result: Array[String] = []
	var handle: DirAccess = DirAccess.open(directory+"/queue")
	if handle != null:
		for filename: String in handle.get_files():
			if filename.begins_with("report_") and filename.ends_with(".json"):
				result.append(directory+"/queue/"+filename)
	result.sort()
	return result
