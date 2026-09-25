extends RefCounted

const MAX_OFFLINE_SECONDS := 72 * 3600
const CLOCK_TOLERANCE_SECONDS := 300


static func verify(envelope: Dictionary, public_key_pem: String, install_id: String, nonce: String = "") -> Dictionary:
	if not envelope.get("payload") is String or not envelope.get("signature") is String:
		return {}
	var bytes := Marshalls.base64_to_raw(envelope["payload"])
	var signature := Marshalls.base64_to_raw(envelope["signature"])
	if bytes.is_empty() or bytes.size() > 8192 or signature.size() != 256:
		return {}
	var key := CryptoKey.new()
	if key.load_from_string(public_key_pem, true) != OK:
		return {}
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	if not Crypto.new().verify(HashingContext.HASH_SHA256, hashing.finish(), signature, key):
		return {}
	var data: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not data is Dictionary or int(data.get("protocol", 0)) != 1:
		return {}
	if String(data.get("install_id", "")) != install_id or (not nonce.is_empty() and data.get("nonce") != nonce):
		return {}
	if not String(data.get("status", "")) in ["active", "invalid", "other_device", "expired", "revoked"]:
		return {}
	var issued := int(data.get("issued_at", 0))
	if issued <= 0:
		return {}
	if data["status"] == "active":
		var until := int(data.get("valid_until", 0))
		if until <= issued or until > issued + MAX_OFFLINE_SECONDS or until > int(data.get("expires_at", 0)):
			return {}
		if not is_hex_id(String(data.get("session_token", "")), 64):
			return {}
	return data


static func is_hex_id(value: String, length: int) -> bool:
	if value.length() != length:
		return false
	for character in value:
		if not character in "0123456789abcdef":
			return false
	return true


static func effective_now(data: Dictionary, received_local: int, now_local: int, elapsed_seconds: int, high_water: int) -> int:
	if data.is_empty() or now_local < high_water - CLOCK_TOLERANCE_SECONDS or now_local < received_local - CLOCK_TOLERANCE_SECONDS:
		return -1
	return int(data.get("issued_at", 0)) + maxi(maxi(now_local, high_water) - received_local, elapsed_seconds)


static func permits_edit(data: Dictionary, now: int) -> bool:
	return now > 0 and data.get("status") == "active" and now < int(data.get("valid_until", 0)) and now < int(data.get("expires_at", 0))
