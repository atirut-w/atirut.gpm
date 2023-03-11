class_name GPM
extends RefCounted
## Godot Package Manager API


# Internal function for getting the [SceneTree].
static func _get_tree() -> SceneTree:
	return Engine.get_main_loop()


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
