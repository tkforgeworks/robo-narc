class_name Uuid
extends RefCounted
## Random (version 4) UUIDs as lowercase 8-4-4-4-12 strings, for tagging
## records that may be sent more than once.

static var _shape := RegEx.create_from_string(
		"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")


static func v4() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4),
			hex.substr(16, 4), hex.substr(20, 12)]


static func is_valid(text: String) -> bool:
	return _shape.search(text) != null
