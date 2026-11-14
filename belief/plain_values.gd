extends RefCounted
# Local boundary helper; no dependency on Person 2's unmerged files.
static func valid(value: Variant, depth: int = 0) -> bool:
	if depth > 16:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY, TYPE_DICTIONARY:
			if value.size() > 2048:
				return false
			for key in value:
				if value is Dictionary:
					if not key is String or not valid(value[key], depth + 1):
						return false
				elif not valid(key, depth + 1):
					return false
			return true
	return false

static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 2147483647 and float(value) == floor(float(value))

static func text(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true
