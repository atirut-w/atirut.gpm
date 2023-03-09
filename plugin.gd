@tool
extends EditorPlugin


var main_panel := preload("res://addons/atirut.gpm/main_panel.tscn").instantiate() as Control


func _enter_tree() -> void:
	get_editor_interface().get_editor_main_screen().add_child(main_panel)
	_make_visible(false) # Can Godot make it invisible automatically please?


func _exit_tree() -> void:
	main_panel.queue_free()
	pass


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	main_panel.visible = visible


func _get_plugin_name() -> String:
	return "Packages"


func _get_plugin_icon() -> Texture2D:
	return null # TODO: Icon
