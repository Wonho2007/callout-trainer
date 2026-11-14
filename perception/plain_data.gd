extends RefCounted
# Reject engine Objects, cycles/deep nesting and non-JSON values at boundaries.
static func valid(value: Variant, depth: int = 0) -> bool:
	if depth > 16:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			if value.size() > 2048:
				return false
			for child in value:
				if not valid(child, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			if value.size() > 256:
				return false
			for key in value:
				if not key is String or not valid(value[key], depth + 1):
					return false
			return true
	return false

static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= 0 and value <= 2147483647

static func keys_exact(value: Dictionary, keys: Array) -> bool:
	if value.size() != keys.size():
		return false
	for key in keys:
		if not value.has(key):
			return false
	return true

static func nonempty(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func equal(a: Variant, b: Variant) -> bool:
	# Godot's Variant comparison can raise for incompatible scalar types.
	if (a is int or a is float) and (b is int or b is float):
		return a == b
	if typeof(a) != typeof(b):
		return false
	if a is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not equal(a[key], b[key]):
				return false
		return true
	if a is Array:
		if a.size() != b.size():
			return false
		for index in range(a.size()):
			if not equal(a[index], b[index]):
				return false
		return true
	return a == b
