extends Node

# Web-only adapter. Calendar data and activation keep their existing paths.
var access: CanvasLayer
var bridge: Object
var web: Object
var import_callback: Object
var update_callback: Object
var access_callback: Object
var last_access_state := ""
var pending_config: ConfigFile
var confirm_import: ConfirmationDialog


func _ready() -> void:
	bridge = Engine.get_singleton("JavaScriptBridge")
	web = bridge.get_interface("DriverWeb")
	import_callback = bridge.create_callback(_import_selected)
	update_callback = bridge.create_callback(_update_checked)
	access_callback = bridge.create_callback(_access_action)
	access.code_input.hide()
	access.activate_button.text = "Wpisz lub wklej kod"
	for connection in access.activate_button.pressed.get_connections():
		access.activate_button.pressed.disconnect(connection["callable"])
	access.activate_button.pressed.connect(func(): web.showAccess())
	web.bindAccess(access_callback)
	access._button("Pobierz kopię kalendarza", _download_backup)
	access._button("Przywróć kopię z pliku", func(): web.chooseBackup(import_callback))
	confirm_import = ConfirmationDialog.new()
	confirm_import.title = "Przywrócić kalendarz?"
	confirm_import.dialog_text = "Kopia zastąpi obecny kalendarz, profile i liczniki. Najpierw pobierz kopię obecnego zapisu. Aktywacja i termin testów pozostaną bez zmian."
	confirm_import.dialog_autowrap = true
	confirm_import.ok_button_text = "Przywróć"
	confirm_import.cancel_button_text = "Anuluj"
	confirm_import.confirmed.connect(_restore_backup)
	add_child(confirm_import)
	if not OS.is_userfs_persistent():
		access.state_error = true
		access.status_label.text = "Safari nie udostępnia trwałego zapisu. Zamknij tryb prywatny i otwórz kalendarz z ikony na ekranie głównym."
	web.ready()
	_sync_access.call_deferred()


func _process(_delta: float) -> void:
	_sync_access()


func _sync_access() -> void:
	var state := JSON.stringify({
		"message": access.status_label.text,
		"busy": not access.pending_nonce.is_empty(),
		"allowed": access.unlocked,
		"storage_error": access.state_error,
		"can_refresh": not access.session_token.is_empty(),
	})
	if state != last_access_state:
		last_access_state = state
		web.accessState(state)


func _access_action(args: Array) -> void:
	if args.size() < 2:
		return
	var action := String(args[0])
	if action == "activate":
		access.code_input.text = String(args[1]).strip_edges()
		access._request_access("activate")
	elif action == "refresh":
		access._request_access("refresh")
	# Re-enable the native form even if a repeated immediate error is identical.
	last_access_state = ""
	_sync_access()


static func parse_backup(text: String) -> ConfigFile:
	if text.length() > 3000000:
		return null
	if text.begins_with("DKCAL1:"):
		text = Marshalls.base64_to_utf8(text.substr(7).strip_edges())
	var config := ConfigFile.new()
	if config.parse(text) != OK or not config.has_section("calendar"):
		return null
	var version: Variant = config.get_value("format", "version", 0)
	if not version is int or version < 0 or version > 1:
		return null
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			var value: Variant = config.get_value(section, key)
			if value is Object:
				return null
	for key in ["manual_overrides", "notes", "worked_seconds_by_day"]:
		if not config.get_value("calendar", key, {}) is Dictionary:
			return null
	if not config.get_value("profiles", "items", {}) is Dictionary:
		return null
	if not config.get_value("calendar", "custom_pattern", []) is Array:
		return null
	return config


func _download_backup() -> void:
	var config := ConfigFile.new()
	if config.load("user://driver_calendar.cfg") != OK and config.load("user://driver_calendar.cfg.bak") != OK:
		access.status_label.text = "Brak czytelnego zapisu do pobrania."
		return
	bridge.download_buffer(config.encode_to_text().to_utf8_buffer(), "Kalendarz-Kierowcy-%s.dkcal" % Time.get_date_string_from_system(), "text/plain")
	access.status_label.text = "Zachowaj pobrany plik w aplikacji Pliki lub iCloud Drive. Kopia zawiera kalendarz i profile, bez kodu aktywacji."


func _import_selected(args: Array) -> void:
	if args.is_empty() or not args[0] is String:
		return
	if not access.unlocked:
		access.status_label.text = "Najpierw aktywuj dostęp, aby przywrócić kalendarz. Pobranie obecnej kopii jest dostępne również po testach."
		return
	pending_config = parse_backup(args[0])
	if pending_config == null:
		access.status_label.text = "Nieprawidłowa kopia lub nowszy format. Obecny kalendarz pozostaje bez zmian."
		return
	confirm_import.popup_centered(Vector2i(580, 280))


func _restore_backup() -> void:
	if pending_config == null or not access.unlocked:
		return
	if access.calendar._write_settings_config(pending_config) != OK:
		access.status_label.text = "Nie udało się przywrócić kopii. Obecny zapis zachowano."
		return
	bridge.force_fs_sync()
	access.calendar._load_settings_from_disk()
	access.calendar._rebuild_calendar()
	access.calendar._apply_main_view_mode()
	pending_config = null
	access.status_label.text = "Przywrócono kalendarz i profile. Sprawdź godziny oraz ewentualny trwający licznik."


func check_update() -> void:
	access.update_label.text = "Sprawdzanie aktualizacji…"
	web.checkUpdate(update_callback)


func _update_checked(args: Array) -> void:
	if not args.is_empty():
		access.update_label.text = String(args[0])
