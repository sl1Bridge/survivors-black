extends Control

const AUDIO_SCENE_PATH := "res://scenes/audio_settings.tscn"
const GRAPHICS_SCENE_PATH := "res://scenes/graphics_settings.tscn"
const CONTROLS_SCENE_PATH := "res://scenes/controls_menu.tscn"
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(340.0, 0.0)
	panel.add_child(content)
	var title := Label.new()
	title.text = "Настройки"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	_add_button(content, "Звук", _open_audio)
	_add_button(content, "Графика", _open_graphics)
	_add_button(content, "Управление", _open_controls)
	_add_button(content, "Назад", _return_to_menu)


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320.0, 44.0)
	button.pressed.connect(callback)
	parent.add_child(button)


func _open_audio() -> void:
	get_tree().change_scene_to_file(AUDIO_SCENE_PATH)


func _open_controls() -> void:
	get_tree().change_scene_to_file(CONTROLS_SCENE_PATH)


func _open_graphics() -> void:
	get_tree().change_scene_to_file(GRAPHICS_SCENE_PATH)


func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
