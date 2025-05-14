class_name utils
static func get_millis() -> int:
	return round(Time.get_unix_time_from_system() * 1000)
