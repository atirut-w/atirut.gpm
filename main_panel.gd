@tool
extends VBoxContainer


func _ready() -> void:
	print("Main panel init")


func _install_from_url() -> void:
	var dialog := InstallDialog.new()
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	
	var url := dialog.url_field.text
	if url == "":
		await _alert("Manifest URL cannot be empty!")
	else:
		GPM._fetch(url)


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
