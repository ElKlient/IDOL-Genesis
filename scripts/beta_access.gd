extends CanvasLayer

const Lease = preload("res://scripts/beta_lease.gd")
const STATE_PATH := "user://driver_beta_access.cfg"
const PUBLIC_KEY_PATH := "res://beta/lease-public.pem"
const RELEASE_PATH := "res://beta/release.json"
const REFRESH_SECONDS := 12 * 3600

var calendar: Control
var release: Dictionary
var install_id := ""
var session_token := ""
var envelope: Dictionary = {}
var lease: Dictionary = {}
var received_local := 0
var high_water := 0
var loaded_ticks := 0
var loaded_elapsed := 0
var last_refresh_ticks := -100000000
var last_tick := -1
var last_saved_minute := -1
var pending_nonce := ""
var request_kind := ""
var http: HTTPRequest
var update_http: HTTPRequest
var panel: ColorRect
var box: VBoxContainer
var status_label: Label
var code_input: LineEdit
var activate_button: Button
var refresh_button: Button
var close_button: Button
var data_text: TextEdit
var data_back_button: Button
var update_label: Label
var update_button: Button
var key_pem := ""
var state_error := false
var unlocked := false
var web_tools: Node


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	release = JSON.parse_string(FileAccess.get_file_as_string(RELEASE_PATH))
	key_pem = FileAccess.get_file_as_string(PUBLIC_KEY_PATH)
	_load_state()
	_build_gate()
	if OS.has_feature("web"):
		web_tools = preload("res://scripts/web_beta_tools.gd").new()
		web_tools.access = self
		add_child(web_tools)
	var open_button := Button.new()
	open_button.text = "Wersja beta i aktualizacje"
	open_button.custom_minimum_size.y = 58
	open_button.add_theme_font_size_override("font_size", 19)
	open_button.pressed.connect(show_panel)
	calendar.options_root.add_child(open_button)
	http = HTTPRequest.new()
	http.timeout = 15.0
	http.body_size_limit = 16384
	http.max_redirects = 0
	add_child(http)
	http.request_completed.connect(_request_completed)
	update_http = HTTPRequest.new()
	update_http.timeout = 15.0
	update_http.body_size_limit = 16384
	update_http.max_redirects = 0
	add_child(update_http)
	update_http.request_completed.connect(_update_completed)
	_refresh_gate()
	_update_status()
	if not session_token.is_empty():
		_request_access("refresh")


func _build_gate() -> void:
	panel = ColorRect.new()
	panel.color = Color("101a28")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 18)
	scroll.add_child(box)
	_label("Kalendarz Kierowcy — BETA", 28)
	_label("Wersja %s" % release.get("version_name", ""), 17)
	status_label = _label("Wpisz kod otrzymany od organizatora testów.", 21)
	code_input = LineEdit.new()
	code_input.placeholder_text = "DK-XXXXX-XXXXX-XXXXX-XXXXX"
	code_input.max_length = 40
	code_input.custom_minimum_size.y = 62
	code_input.add_theme_font_size_override("font_size", 22)
	box.add_child(code_input)
	activate_button = _button("Aktywuj kod na tym telefonie", func(): _request_access("activate"))
	refresh_button = _button("Sprawdź dostęp przez internet", func(): _request_access("refresh"))
	_label("30 dni od pierwszej aktywacji. Do 72 godzin bez internetu po potwierdzeniu dostępu, najwyżej do końca testów. Aktualizacje nie odnawiają okresu testowego.", 18)
	_label("Profile, godziny i notatki pozostają na telefonie. Usługa otrzymuje kod, losowy identyfikator instalacji i dane potrzebne do potwierdzenia dostępu.", 17)
	update_label = _label("Aktualizację instaluj na obecną aplikację. Nie odinstalowuj jej i nie czyść danych." if not OS.has_feature("web") else "Otwieraj kalendarz zawsze z tej samej ikony. Nie usuwaj aplikacji ani danych Safari. Regularnie pobieraj kopię kalendarza.", 18)
	_button("Sprawdź aktualizację", _check_update)
	update_button = _button("Pobierz aktualizację", func(): OS.shell_open(String(release["service_url"]) + "/download"))
	update_button.visible = false
	_button("Odczytaj zapisane dane", _show_saved_data)
	_button("Kopiuj kopię kalendarza", _copy_calendar)
	data_text = TextEdit.new()
	data_text.editable = false
	data_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	data_text.custom_minimum_size.y = 380
	data_text.add_theme_font_size_override("font_size", 18)
	data_text.visible = false
	box.add_child(data_text)
	close_button = _button("Wróć do kalendarza", func(): panel.hide())


func _label(text: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	box.add_child(result)
	return result


func _button(text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 60
	result.add_theme_font_size_override("font_size", 20)
	result.pressed.connect(action)
	box.add_child(result)
	return result


func show_panel() -> void:
	panel.show()
	_update_status()


func _load_state() -> void:
	var config := ConfigFile.new()
	var error := config.load(STATE_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		error = config.load(STATE_PATH + ".bak")
		if error != OK:
			state_error = true
			return
	install_id = String(config.get_value("access", "install_id", ""))
	if not Lease.is_hex_id(install_id, 32):
		install_id = Crypto.new().generate_random_bytes(16).hex_encode()
	session_token = String(config.get_value("access", "session_token", ""))
	var stored: Variant = config.get_value("access", "envelope", {})
	if stored is Dictionary:
		envelope = stored
	lease = Lease.verify(envelope, key_pem, install_id)
	received_local = int(config.get_value("access", "received_local", 0))
	high_water = int(config.get_value("access", "high_water", 0))
	loaded_elapsed = maxi(0, high_water - received_local)
	loaded_ticks = Time.get_ticks_msec()
	# Save identity before activation; interrupted requests must retry on the same installation.
	if not _save_state():
		state_error = true


func _save_state() -> bool:
	var config := ConfigFile.new()
	config.set_value("access", "install_id", install_id)
	config.set_value("access", "session_token", session_token)
	config.set_value("access", "envelope", envelope)
	config.set_value("access", "received_local", received_local)
	config.set_value("access", "high_water", high_water)
	if config.save(STATE_PATH + ".tmp") != OK:
		return false
	var valid := ConfigFile.new()
	if valid.load(STATE_PATH + ".tmp") != OK:
		return false
	if valid.load(STATE_PATH) == OK:
		if DirAccess.copy_absolute(STATE_PATH, STATE_PATH + ".bak") != OK:
			return false
	var saved := DirAccess.rename_absolute(STATE_PATH + ".tmp", STATE_PATH) == OK
	if saved and OS.has_feature("web"):
		Engine.get_singleton("JavaScriptBridge").force_fs_sync()
	return saved


func _now() -> int:
	return Lease.effective_now(lease, received_local, int(Time.get_unix_time_from_system()), loaded_elapsed + int((Time.get_ticks_msec() - loaded_ticks) / 1000), high_water)


func _process(_delta: float) -> void:
	var seconds := int(Time.get_ticks_msec() / 1000)
	if seconds == last_tick or not is_instance_valid(calendar):
		return
	last_tick = seconds
	_refresh_gate()
	var local_now := int(Time.get_unix_time_from_system())
	var minute := int(local_now / 60)
	if not state_error and minute != last_saved_minute:
		last_saved_minute = minute
		high_water = maxi(high_water, local_now)
		if not _save_state():
			state_error = true
	if not session_token.is_empty() and pending_nonce.is_empty() and Time.get_ticks_msec() - last_refresh_ticks > REFRESH_SECONDS * 1000:
		_request_access("refresh")


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN] and is_instance_valid(http) and not session_token.is_empty():
		_request_access("refresh")


func _refresh_gate() -> void:
	var allowed := not state_error and Lease.permits_edit(lease, _now())
	if allowed != unlocked or (not allowed and not panel.visible):
		unlocked = allowed
		if not allowed:
			for child in calendar.get_children():
				if child is Window:
					child.hide()
		calendar.process_mode = Node.PROCESS_MODE_INHERIT if allowed else Node.PROCESS_MODE_DISABLED
		panel.visible = not allowed
		_update_status()
	# Calendar starts disabled before a code is accepted.
	if not allowed:
		calendar.process_mode = Node.PROCESS_MODE_DISABLED
	close_button.visible = allowed
	refresh_button.disabled = session_token.is_empty() or not pending_nonce.is_empty()
	activate_button.disabled = state_error or not pending_nonce.is_empty()


func _update_status() -> void:
	if state_error:
		status_label.text = "Nie można zapisać lub odczytać aktywacji. Dane kalendarza są zachowane. Sprawdź wolne miejsce i uruchom aplikację ponownie."
	elif unlocked:
		status_label.text = "Dostęp aktywny. Pozostało %d dni.\nKoniec testów (UTC): %s" % [int(ceil(float(int(lease["expires_at"]) - _now()) / 86400.0)), Time.get_datetime_string_from_unix_time(int(lease["expires_at"]), true)]
	elif lease.get("status") == "revoked":
		status_label.text = "Dostęp testowy został zakończony przez organizatora. Zapisane dane pozostają dostępne poniżej."
	elif lease.get("status") == "expired" or (int(lease.get("expires_at", 0)) > 0 and _now() >= int(lease["expires_at"])):
		status_label.text = "Okres testowy zakończony. Możesz odczytać i skopiować zapisane dane. Poproś organizatora o przedłużenie, a potem sprawdź dostęp."
	elif not session_token.is_empty():
		status_label.text = "Połącz się z internetem, aby potwierdzić dostęp. Zapis kalendarza i liczniki zostały zachowane."


func _request_access(kind: String) -> void:
	if state_error or not pending_nonce.is_empty() or (kind == "refresh" and session_token.is_empty()):
		return
	if kind == "activate" and code_input.text.strip_edges().is_empty():
		status_label.text = "Wpisz kod otrzymany od organizatora."
		return
	pending_nonce = Crypto.new().generate_random_bytes(16).hex_encode()
	request_kind = kind
	last_refresh_ticks = Time.get_ticks_msec()
	var body := {"install_id": install_id, "nonce": pending_nonce}
	if kind == "activate":
		body["code"] = code_input.text.strip_edges()
	else:
		body["session_token"] = session_token
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not OS.has_feature("web"):
		headers.append("User-Agent: KalendarzKierowcyBeta/0.1.0")
	var service_url := String(release["service_url"])
	if OS.has_feature("web"):
		service_url = String(Engine.get_singleton("JavaScriptBridge").eval("window.location.origin"))
	var error := http.request(service_url + "/api/beta/" + kind, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		pending_nonce = ""
		status_label.text = "Nie udało się połączyć. Sprawdź internet i spróbuj ponownie."
	else:
		status_label.text = "Sprawdzanie dostępu…"
	_refresh_gate()


func _request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var nonce := pending_nonce
	pending_nonce = ""
	var parser := JSON.new()
	var value: Variant = null
	if not body.is_empty() and parser.parse(body.get_string_from_utf8()) == OK:
		value = parser.data
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or not value is Dictionary:
		last_refresh_ticks = Time.get_ticks_msec() - (REFRESH_SECONDS - 300) * 1000
		status_label.text = "Nie udało się potwierdzić dostępu. Spróbuj ponownie po połączeniu z internetem. Dane kalendarza są zachowane."
		_refresh_gate()
		return
	var verified := Lease.verify(value, key_pem, install_id, nonce)
	if verified.is_empty():
		status_label.text = "Nieprawidłowe potwierdzenie dostępu. Spróbuj ponownie później."
		return
	if verified["status"] in ["invalid", "other_device"]:
		status_label.text = "Kod jest nieprawidłowy." if verified["status"] == "invalid" else "Kod jest już przypisany do innego telefonu. Poproś organizatora o zmianę telefonu."
		if request_kind == "refresh":
			envelope = value
			lease = verified
			_save_state()
		_refresh_gate()
		return
	envelope = value
	lease = verified
	if verified["status"] == "active":
		session_token = String(verified["session_token"])
		code_input.text = ""
	received_local = int(Time.get_unix_time_from_system())
	high_water = received_local
	loaded_ticks = Time.get_ticks_msec()
	loaded_elapsed = 0
	state_error = not _save_state()
	_refresh_gate()
	_update_status()


func _check_update() -> void:
	if OS.has_feature("web"):
		web_tools.check_update()
		return
	update_label.text = "Sprawdzanie aktualizacji…"
	var error := update_http.request(String(release["service_url"]) + "/api/releases/latest", ["User-Agent: KalendarzKierowcyBeta/0.1.0"])
	if error != OK:
		update_label.text = "Nie udało się sprawdzić aktualizacji. Spróbuj ponownie."


func _update_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var parser := JSON.new()
	var data: Variant = null
	if not body.is_empty() and parser.parse(body.get_string_from_utf8()) == OK:
		data = parser.data
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or not data is Dictionary:
		update_label.text = "Sprawdzenie aktualizacji niedostępne. Spróbuj później."
		return
	var latest: Variant = data.get("release")
	if latest is Dictionary and int(latest.get("version_code", 0)) > int(release["version_code"]):
		update_label.text = "Dostępna wersja %s. Zainstaluj ją na obecną aplikację — bez odinstalowania." % String(latest.get("version_name", ""))
		update_button.show()
	else:
		update_label.text = "Masz aktualną wersję aplikacji."
		update_button.hide()


func _show_saved_data() -> void:
	var config := ConfigFile.new()
	if config.load("user://driver_calendar.cfg") != OK and config.load("user://driver_calendar.cfg.bak") != OK:
		status_label.text = "Nie udało się odczytać zapisu kalendarza. Pliki pozostają bez zmian."
		return
	var lines: Array[String] = ["BIEŻĄCY KALENDARZ"]
	_append_data(lines, config.get_value("calendar", "worked_seconds_by_day", {}), config.get_value("calendar", "notes", {}))
	var profiles: Variant = config.get_value("profiles", "items", {})
	if profiles is Dictionary:
		for id in profiles:
			if profiles[id] is Dictionary:
				lines.append("\nPROFIL %s" % str(id))
				_append_data(lines, profiles[id].get("worked_seconds_by_day", {}), profiles[id].get("notes", {}))
	for field in ["start_unix", "pause_start_unix"]:
		var timestamp := int(config.get_value("work", field, 0))
		if timestamp > 0:
			lines.append("%s (UTC): %s" % ["Start pracy" if field == "start_unix" else "Start pauzy", Time.get_datetime_string_from_unix_time(timestamp, true)])
	data_text.text = "\n".join(lines)
	data_text.show()


func _append_data(lines: Array[String], hours: Variant, notes: Variant) -> void:
	if hours is Dictionary:
		var days: Array = hours.keys()
		days.sort()
		for day in days:
			var seconds := int(hours[day])
			lines.append("%s: %dh %02dmin" % [str(day), int(seconds / 3600), int(seconds / 60) % 60])
	if notes is Dictionary:
		for day in notes:
			lines.append("%s: %s" % [str(day), str(notes[day])])


func _copy_calendar() -> void:
	var file := FileAccess.open("user://driver_calendar.cfg", FileAccess.READ)
	if file == null:
		status_label.text = "Brak czytelnego zapisu. Niczego nie zmieniono."
		return
	DisplayServer.clipboard_set("DKCAL1:" + Marshalls.raw_to_base64(file.get_buffer(file.get_length())))
	status_label.text = "Skopiowano pełny zapis kalendarza. Wklej go do swojego pliku tekstowego i zachowaj jako kopię. Nie zawiera kodu aktywacji."
