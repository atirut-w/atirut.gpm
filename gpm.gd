class_name GPM
extends RefCounted
## Godot Package Manager API


## Installs a package from its manifest file.
static func install_from_json(manifest: String) -> void:
	var dict := JSON.parse_string(manifest)
	if dict == null or typeof(dict) != TYPE_DICTIONARY:
		_alert("Bad manifest file. See log for more info.")
		return
	var package := PackageManifest.from_dict(dict)
	if package == null:
		_alert("Bad manifest file. See log for more info.")
		return


# Internal function for getting the [SceneTree].
static func _get_tree() -> SceneTree:
	return Engine.get_main_loop()


static func _alert(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	
	_get_tree().root.add_child(dialog)
	dialog.popup_centered()
	await SignalAwaiter.wait_any([dialog.canceled, dialog.confirmed])
	dialog.queue_free()


# Internal function for async HTTP fetching
static func _fetch(url: String) -> String:
	var http := HTTPRequest.new()
	var err: Error
	_get_tree().root.add_child(http)
	
	err = http.request(url)
	assert(err == OK, "could not fetch %s: %d" % [url, err])
	var response := await http.request_completed as Array
	assert(response[0] == HTTPRequest.RESULT_SUCCESS, "could not fetch %s: %d" % [url, response[0]])
	
	http.queue_free()
	return (response[3] as PackedByteArray).get_string_from_ascii()


## Metadata for packages.
class PackageManifest extends RefCounted:
	## Package's name used for package management. Package names should use
	## reverse domain name notation to avoid name conflicts.
	var name: String
	## Package version.
	var version: int
	## Optional manifest URL for checking updates.
	var update_url: String
	## List of dependencies.
	var dependendies: Array[String]
	
	## List of files to be installed for this package.
	var files: Array[String]
	## List of files to keep when updating.
	var keep_files: Array[String]
	
	const _REQUIRED_KEYS: Array[String] = [
		"name",
		"version",
		"files",
	]
	
	
	## Create a package manifest data from a dictionary.
	static func from_dict(dict: Dictionary) -> PackageManifest:
		if dict == null:
			push_error("manifest dictionary cannot be null")
			return null
		var package := PackageManifest.new()
		
		for key in _REQUIRED_KEYS:
			if not key in dict:
				push_error("manifest does not contain a required key: '%s'" % key)
				return null
		
		for key in dict:
			if key in package:
				if typeof(package[key]) == typeof(dict[key]):
					if typeof(package[key]) == TYPE_ARRAY:
						for i in dict[key]:
							package[key].append(i)
					else:
						package[key] = dict[key]
				elif typeof(package[key]) == TYPE_INT && typeof(dict[key]) == TYPE_FLOAT:
					package[key] = dict[key] as int
				else:
					push_error("type mismatch for key '%s'(expected %d, got %d)" % [key, typeof(package[key]), typeof(dict[key])])
					return
			else:
				push_warning("key '%s' is not used." % key)
		
		return package


## Utility for waiting one or more signals
class SignalAwaiter extends RefCounted:
	## Wait for any signals to emit
	static func wait_any(signals: Array[Signal]) -> void:
		var emitter := Emitter.new()
		for sig in signals:
			sig.connect(emitter.emit)
		await emitter.emitted
	
	
	## Wait for all signals to emit
	static func wait_all(signals: Array[Signal]) -> void:
		var emitter := Emitter.new()
		for sig in signals:
			sig.connect(emitter.emit)
		for i in signals.size():
			await emitter.emitted
	
	
	class Emitter extends RefCounted:
		signal emitted
		
		
		func emit() -> void:
			emitted.emit()
