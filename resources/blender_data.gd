class_name BlenderData

enum Stability {
	ALPHA,
	BETA,
	RELEASE_CANDIDATE,
	STABLE,
	EXPERIMENTAL,
	CUSTOM,
	UNKNOWN
}

## major.minor.patch
var version: = ""
## ISO8601 Timestamp
var timestamp: = ""
## Default Format: DDth MMMM, YYYY
var size: = ""
var stability: Stability = Stability.STABLE
var branch: = ""
var build_hash: = ""
var source: = ""
var installation_path: = ""
var os: = ""
var architecture: = ""


func _to_string() -> String:
	return """BlenderData:

		Version           : %s
		Statbility        : %s
		Branch            : %s
		Build Hash        : %s
		Size              : %s
		Timestamp         : %s (%s)
		Source            : %s
		Installation Path : %s
		OS                : %s
		Architecture      : %s

""" % [
	version,
	get_enum_string(&"Stability", stability),
	branch,
	build_hash,
	size,
	timestamp, get_friendly_timestamp(),
	source,
	installation_path,
	os,
	architecture,
]


func get_enum_string(which_enum: StringName, value: int) -> String:
	if get_script() is Script:
		var enum_dict: Dictionary = get_script().get_script_constant_map()[which_enum]
		#print_debug(JSON.stringify(enum_dict, "\t", false))
		for key in enum_dict:
			if enum_dict[key] == value:
				return key
	printerr("Value is out of range for the given enum. %s : %s" % [which_enum, value])
	return ""


func get_friendly_timestamp(_timestamp: = timestamp, format: = "{day} {month}, {year}", use_format_always: = false) -> String:
	return Helper.get_friendly_date(timestamp, format, use_format_always)


static func get_stability_from_string(string: String) -> Stability:
	match string.capitalize():
		"Alpha":
			return Stability.ALPHA
		"Beta":
			return Stability.BETA
		"Release Candidate":
			return Stability.RELEASE_CANDIDATE
		"Stable", "Lts", "": # "Lts" and not "LTS" because string.capitalize()
			return Stability.STABLE
		"Experimental":
			return Stability.EXPERIMENTAL
		"Custom":
			return Stability.CUSTOM
		"Unknown", _:
			return Stability.UNKNOWN


static func get_string_from_stability(_stability: Stability) -> String:
	match _stability:
		BlenderData.Stability.ALPHA:
			return "Alpha"
		BlenderData.Stability.BETA:
			return "Beta"
		BlenderData.Stability.RELEASE_CANDIDATE:
			return "Release Candidate"
		BlenderData.Stability.STABLE:
			return "Stable"
		BlenderData.Stability.EXPERIMENTAL:
			return "Experimental"
		BlenderData.Stability.CUSTOM:
			return "Custom"
		BlenderData.Stability.UNKNOWN, _:
			return "Unknown"


func get_short_version() -> String:
	return version.get_slice(".", 0) + "." + version.get_slice(".", 1)
