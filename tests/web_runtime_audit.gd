extends SceneTree

# Test-export only: never included in the distributed beta. Run twice on the
# same origin to check actual browser IndexedDB across a WASM restart.
const Main = preload("res://scripts/main.gd")
const Lease = preload("res://scripts/beta_lease.gd")
var results: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	results.append(("PASS" if ok else "FAIL") + " | " + label)


func _run() -> void:
	var app := Main.new()
	root.add_child(app)
	await process_frame
	check(OS.is_userfs_persistent(), "Browser persistent filesystem")
	check(Crypto.new().generate_random_bytes(16).size() == 16, "Web cryptographic random identity")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://beta/web-audit-fixture.json"))
	var pem := FileAccess.get_file_as_string("res://beta/lease-public.pem")
	check(Lease.verify(fixture, pem, "1".repeat(32), "2".repeat(32)).get("status") == "active", "Web verifies server RSA lease")
	var damaged := Marshalls.base64_to_raw(fixture["signature"])
	damaged[0] = damaged[0] ^ 1
	fixture["signature"] = Marshalls.raw_to_base64(damaged)
	check(Lease.verify(fixture, pem, "1".repeat(32)).is_empty(), "Web rejects invalid signature")
	var marker := ConfigFile.new()
	if marker.load("user://web_runtime_audit_marker.cfg") == OK:
		check(int(app.worked_seconds_by_day.get("2026-09-25", 0)) == 30600, "Hours survive browser restart")
		check(app.notes.get("2026-09-25") == "Test Łękno", "Notes survive browser restart")
		check(app.saved_profiles.get("1", {}).get("notes", {}).get("2026-09-25") == "Test Łękno", "Profile survives browser restart")
		check(app.work_start_unix == int(marker.get_value("test", "start")), "Shift start survives browser restart")
	else:
		app.worked_seconds_by_day["2026-09-25"] = 30600
		app.notes["2026-09-25"] = "Test Łękno"
		app.active_profile_index = 1
		app.work_start_unix = int(Time.get_unix_time_from_system()) - 3600
		app.work_start_day_key = "2026-09-25"
		check(app._save_settings_to_disk(), "Write hours, notes, profile and shift")
		marker.set_value("test", "start", app.work_start_unix)
		marker.save("user://web_runtime_audit_marker.cfg")
		Engine.get_singleton("JavaScriptBridge").force_fs_sync()
		await create_timer(2.0).timeout
		results.append("Reload this test to verify retained data.")
	Engine.get_singleton("JavaScriptBridge").eval("document.getElementById('status').textContent = " + JSON.stringify("\n".join(results)))
