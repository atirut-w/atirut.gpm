@tool
extends VBoxContainer


func _ready() -> void:
	print("Main panel init")


func _install_from_file() -> void:
	var dialog := EditorFileDialog.new()
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.json", "GPM Manifest File")
	
	add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))
	var path := await dialog.file_selected as String
	dialog.queue_free()
	
	var file := FileAccess.open(path, FileAccess.READ)
	GPM.install_from_json(file.get_as_text())


func _install_from_url() -> void:
	var install_dialog := InstallDialog.new()
	install_dialog.canceled.connect(func(): install_dialog.queue_free())
	add_child(install_dialog)
	install_dialog.popup_centered()
	await install_dialog.confirmed
	
	var url := install_dialog.url_field.text
	if url == "":
		await GPM._alert("Manifest URL cannot be empty!")
	else:
		var status_dialog := StatusDialog.new()
		status_dialog.title = "Downloading manifest..."
		status_dialog.status = "Downloading manifest..."
		add_child(status_dialog)
		
		status_dialog.popup_centered()
		var manifest := await GPM._fetch(url)
		status_dialog.queue_free()
		
		if manifest == "":
			await GPM._alert("Invalid URL. See log for more info.")
		else:
			GPM.install_from_json(manifest)
	
	install_dialog.queue_free()


class InstallDialog extends ConfirmationDialog:
	var container := VBoxContainer.new()
	var url_field := LineEdit.new()
	var package_info := RichTextLabel.new()
	
	func _ready() -> void:
		title = "Install from manifest URL"
		ok_button_text = "Install"
		
		url_field.anchors_preset = Control.PRESET_HCENTER_WIDE
		url_field.placeholder_text = "Manifest URL"
		if DisplayServer.clipboard_get() != "":
			url_field.text = DisplayServer.clipboard_get()
		container.add_child(url_field)
		
		add_child(container)


class StatusDialog extends AcceptDialog:
	func _ready() -> void:
		get_ok_button().visible = false
