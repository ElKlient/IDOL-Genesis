extends SceneTree

const Main = preload("res://scripts/main.gd")
const Access = preload("res://scripts/beta_access.gd")
const Lease = preload("res://scripts/beta_lease.gd")
var passed := 0
var failed := 0


func _initialize() -> void:
	if OS.get_name() != "Linux" or not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/driver-calendar-audit-"):
		printerr("Use isolated /tmp/driver-calendar-audit-* XDG_DATA_HOME on Linux.")
		quit(2)
		return
	_run.call_deferred()


func check(label: String, condition: bool) -> void:
	if condition: passed += 1
	else: failed += 1
	print("%s | %s" % ["PASS" if condition else "FAIL", label])


func settle() -> void:
	for _i in range(6): await process_frame


func signed(data: Dictionary, key: CryptoKey) -> Dictionary:
	var text := JSON.stringify(data)
	return {"payload": Marshalls.utf8_to_base64(text), "signature": Marshalls.raw_to_base64(Crypto.new().sign(HashingContext.HASH_SHA256, text.sha256_buffer(), key))}


func _run() -> void:
	for path in [Main.SETTINGS_PATH, Main.SETTINGS_BACKUP_PATH, Main.SETTINGS_TEMP_PATH, Main.SETTINGS_BACKUP_PATH + ".tmp", Access.STATE_PATH, Access.STATE_PATH + ".bak", Access.STATE_PATH + ".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	root.size = Vector2i(720, 1280)
	root.content_scale_size = root.size
	var old := ConfigFile.new()
	old.set_value("calendar", "current_year", 2026)
	old.set_value("calendar", "current_month", 9)
	old.set_value("calendar", "notes", {"2026-09-25": "Test aktualizacji"})
	old.set_value("calendar", "worked_seconds_by_day", {"2026-09-25": 30600})
	old.set_value("calendar", "manual_overrides", {"2026-09-25": 1})
	old.set_value("calendar", "custom_pattern", [1,1,2,2])
	old.set_value("profiles", "items", {"1": {"notes": {"2026-09-24": "Profil"}, "worked_seconds_by_day": {"2026-09-24": 7200}}})
	old.set_value("work", "start_unix", 1700000000)
	old.set_value("work", "pause_start_unix", 1699990000)
	old.set_value("extension", "keep_me", "unchanged")
	old.save(Main.SETTINGS_PATH)
	var app := Main.new()
	root.add_child(app)
	await settle()
	check("Legacy hours, notes and per-day edits survive load", app.worked_seconds_by_day.get("2026-09-25") == 30600 and app.notes.get("2026-09-25") == "Test aktualizacji" and app.manual_overrides.get("2026-09-25") == 1)
	check("Legacy profile data survives load", app.saved_profiles.get("1", {}).get("worked_seconds_by_day", {}).get("2026-09-24") == 7200)
	check("Active work and rest timestamps survive upgrade", app.work_start_unix == 1700000000 and app.pause_start_unix == 1699990000)
	check("Updated application saves legacy data", app._save_settings_to_disk())
	var written := ConfigFile.new()
	written.load(Main.SETTINGS_PATH)
	check("Unknown sections survive re-save", written.get_value("extension", "keep_me", "") == "unchanged")
	check("Migration records supported format without clearing hours", written.get_value("format", "version", 0) == 1 and written.get_value("calendar", "worked_seconds_by_day", {}).get("2026-09-25") == 30600)
	var access := Access.new()
	access.calendar = app
	root.add_child(access)
	await settle()
	check("Unactivated beta blocks calendar interaction", not access.unlocked and app.process_mode == Node.PROCESS_MODE_DISABLED and access.panel.visible)
	var before := FileAccess.get_file_as_bytes(Main.SETTINGS_PATH)
	var key := Crypto.new().generate_rsa(2048)
	access.key_pem = key.save_to_string(true)
	var issued := 1800000000
	var nonce := "a".repeat(32)
	var data := {"protocol":1,"install_id":access.install_id,"nonce":nonce,"issued_at":issued,"status":"active","session_token":"f".repeat(64),"expires_at":issued+30*86400,"valid_until":issued+72*3600}
	var envelope := signed(data,key)
	check("Signed lease verifies", not Lease.verify(envelope,access.key_pem,access.install_id,nonce).is_empty())
	check("Wrong installation and nonce rejected", Lease.verify(envelope,access.key_pem,"b".repeat(32),nonce).is_empty() and Lease.verify(envelope,access.key_pem,access.install_id,"c".repeat(32)).is_empty())
	var tampered := envelope.duplicate()
	tampered["payload"] = Marshalls.utf8_to_base64("{}")
	check("Modified license payload rejected", Lease.verify(tampered,access.key_pem,access.install_id).is_empty())
	access.pending_nonce = nonce
	access.request_kind = "activate"
	access._request_completed(HTTPRequest.RESULT_SUCCESS,200,[],JSON.stringify(envelope).to_utf8_buffer())
	check("Successful activation unlocks calendar", access.unlocked and app.process_mode == Node.PROCESS_MODE_INHERIT and not access.panel.visible)
	check("Activation does not modify calendar file", FileAccess.get_file_as_bytes(Main.SETTINGS_PATH) == before)
	var identity := access.install_id
	access._load_state()
	check("Activation survives application restart", access.install_id == identity and access.lease.get("expires_at",0) == data["expires_at"] and access.session_token == data["session_token"])
	access._request_completed(HTTPRequest.RESULT_CANT_CONNECT,0,[],PackedByteArray())
	check("Network outage retains valid offline permission", access.unlocked)
	var now := int(Time.get_unix_time_from_system())
	check("Clock rollback requires online verification", Lease.effective_now(data,now,now-301,0,now) == -1)
	check("Offline permission expires at 72h boundary", Lease.permits_edit(data,issued+72*3600-1) and not Lease.permits_edit(data,issued+72*3600))
	check("Trial expires at exact 30-day boundary", not Lease.permits_edit(data,issued+30*86400))
	access.loaded_elapsed = 72*3600
	access._refresh_gate()
	check("Running app locks when offline permission expires", not access.unlocked and access.panel.visible and app.process_mode == Node.PROCESS_MODE_DISABLED)
	check("Expired beta preserves all calendar bytes and timers", FileAccess.get_file_as_bytes(Main.SETTINGS_PATH) == before and app.work_start_unix == 1700000000 and app.pause_start_unix == 1699990000)
	access._show_saved_data()
	check("Expired beta still exposes saved hours and notes", access.data_text.text.contains("8h 30min") and access.data_text.text.contains("Test aktualizacji"))
	app._reset_calendar_settings()
	check("Calendar reset does not reset license or trial", FileAccess.file_exists(Access.STATE_PATH) and access.lease["expires_at"] == data["expires_at"])
	access.queue_free()
	app.process_mode = Node.PROCESS_MODE_INHERIT
	await settle()
	written.set_value("format", "version", 99)
	written.save(Main.SETTINGS_PATH)
	before = FileAccess.get_file_as_bytes(Main.SETTINGS_PATH)
	app._load_settings_from_disk()
	check("Newer unsupported format blocks old app writes", app.storage_load_failed and not app._save_settings_to_disk())
	check("Unsupported future save remains byte-identical", before == FileAccess.get_file_as_bytes(Main.SETTINGS_PATH))
	for control_name in ["settings_panel", "schedule_option", "system_work_spin", "system_home_spin", "start_input", "fixed_start_toggle", "fixed_start_option", "weekly_rest_toggle", "custom_panel", "custom_length_spin", "error_label"]:
		var control = app.get(control_name)
		if is_instance_valid(control) and control.get_parent() == null:
			control.free()
	app.free()
	await settle()
	print("RESULT | passed=%d failed=%d" % [passed,failed])
	quit(0 if failed == 0 else 1)
