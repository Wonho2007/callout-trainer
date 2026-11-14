extends RefCounted
# Runtime subset used by the checked-in comms.v1 schema. Not a general JSON
# Schema implementation. Fails closed for unsupported validation keywords.
const Data = preload("res://perception/plain_data.gd")
var _schema: Dictionary

func _init(schema: Dictionary) -> void:
	_schema = schema.duplicate(true)

func valid(message: Dictionary) -> bool:
	return Data.valid(message) and _matches(message, _schema)

func _matches(value: Variant, rule: Dictionary) -> bool:
	for key in rule:
		if key not in ["$schema", "title", "description", "oneOf", "anyOf", "const", "enum",
				"type", "minLength", "minimum", "properties", "required", "additionalProperties"]:
			return false
	if rule.has("const") and not Data.equal(value, rule["const"]):
		return false
	if rule.has("enum"):
		var enum_match: bool = false
		for candidate in rule["enum"]:
			if Data.equal(value, candidate):
				enum_match = true
		if not enum_match:
			return false
	for choice in ["oneOf", "anyOf"]:
		if rule.has(choice):
			var matches: int = 0
			for branch in rule[choice]:
				if _matches(value, branch):
					matches += 1
			if matches == 0 or (choice == "oneOf" and matches != 1):
				return false
	if rule.has("type"):
		match rule.type:
			"object":
				if not value is Dictionary:
					return false
				for key in rule.get("required", []):
					if not value.has(key):
						return false
				var properties: Dictionary = rule.get("properties", {})
				for key in value:
					if not properties.has(key):
						if rule.get("additionalProperties", true) == false:
							return false
					elif not _matches(value[key], properties[key]):
						return false
			"string":
				if not value is String or value.length() < rule.get("minLength", 0):
					return false
			"integer":
				if not Data.integer(value) or value < rule.get("minimum", 0):
					return false
			"null":
				if value != null:
					return false
			_:
				return false
	return true
