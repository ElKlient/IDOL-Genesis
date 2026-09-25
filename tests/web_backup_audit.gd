extends SceneTree

const WebTools = preload("res://scripts/web_beta_tools.gd")
var passed := 0
var failed := 0


func _initialize() -> void:
	var config := ConfigFile.new()
	config.set_value("format", "version", 1)
	config.set_value("calendar", "worked_seconds_by_day", {"2026-09-25": 30600})
	config.set_value("calendar", "notes", {"2026-09-25": "Zwolle → Łękno"})
	config.set_value("profiles", "items", {"1": {"notes": {"2026-09-25": "Profil 1"}}})
	config.set_value("work", "start_unix", 1758790800)
	var text := config.encode_to_text()
	var restored: ConfigFile = WebTools.parse_backup(text)
	check(restored != null and restored.get_value("calendar", "worked_seconds_by_day")["2026-09-25"] == 30600, "Backup preserves work hours")
	check(restored.get_value("profiles", "items")["1"]["notes"]["2026-09-25"] == "Profil 1", "Backup preserves profiles")
	check(restored.get_value("work", "start_unix") == 1758790800, "Backup preserves running shift start")
	restored = WebTools.parse_backup("DKCAL1:" + Marshalls.utf8_to_base64(text))
	check(restored != null and restored.get_value("calendar", "notes")["2026-09-25"] == "Zwolle → Łękno", "Android text backup preserves Polish characters")
	check(WebTools.parse_backup("[access]\ninstall_id=\"abc\"") == null, "License-only file is rejected")
	config.set_value("format", "version", 2)
	check(WebTools.parse_backup(config.encode_to_text()) == null, "Future backup cannot overwrite current data")
	config.set_value("format", "version", 1)
	config.set_value("calendar", "notes", "invalid")
	check(WebTools.parse_backup(config.encode_to_text()) == null, "Invalid calendar structure is rejected")
	check(WebTools.parse_backup("x".repeat(3000001)) == null, "Oversized backup is rejected")
	print("RESULT | passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s | %s" % ["PASS" if ok else "FAIL", label])
