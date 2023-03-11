@tool
extends VBoxContainer


func _ready() -> void:
	print("Main panel init")


func _install_from_url() -> void:
	var install_dialog := InstallDialog.new()
	install_dialog.canceled.connect(func(): install_dialog.queue_free())
	add_child(install_dialog)
	install_dialog.popup_centered()
	await install_dialog.confirmed
	
	var url := install_dialog.url_field.text
	if url == "":
		await _alert("Manifest URL cannot be empty!")
	else:
		var status_dialog := StatusDialog.new()
		status_dialog.title = "Downloading manifest..."
		status_dialog.status = "Downloading manifest..."
		add_child(status_dialog)
		
		status_dialog.popup_centered()
		var manifest := await GPM._fetch(url)
		status_dialog.queue_free()
		
		if manifest == "":
			_alert("Invalid manifest file or bad URL. See log for more info.")
	
	install_dialog.queue_free()


func _alert(message: String) -> void:
	var dialog := AcceptDialog.new()
	var label := Label.new()
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.text = message
	dialog.add_child(label)
	
	add_child(dialog)
	dialog.popup_centered()
	await SignalAwaiter.wait_any([dialog.canceled, dialog.confirmed])
	dialog.queue_free()


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
	var _label := Label.new()
	var status: String:
		set(value):
			_label.text = value
		get:
			return _label.text
	
	func _ready() -> void:
		get_ok_button().visible = false
		_label.anchors_preset = Control.PRESET_FULL_RECT
		add_child(_label)


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
