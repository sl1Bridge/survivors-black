extends Control

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

var sfx_slider: HSlider
var music_slider: HSlider
var sfx_value_label: Label
var music_value_label: Label
var profile: Node


func configure(profile_node: Node) -> void:
	profile = profile_node


func _ready() -> void:
	if not is_instance_valid(profile):
		profile = get_node("/root/GameProfile")
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(520.0, 0.0)
	panel.add_child(content)
	var title := Label.new()
	title.text = "Настройки"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	sfx_slider = _add_volume_control(content, "Звуки", float(profile.get("sfx_volume")), true)
	music_slider = _add_volume_control(content, "Музыка", float(profile.get("music_volume")), false)
	var back_button := Button.new()
	back_button.text = "Назад"
	back_button.pressed.connect(_return_to_menu)
	content.add_child(back_button)


func _add_volume_control(parent: VBoxContainer, title: String, initial_value: float, is_sfx: bool) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := Label.new()
	name_label.text = title
	name_label.custom_minimum_size = Vector2(130.0, 0.0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = initial_value
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(52.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = "%d%%" % roundi(initial_value)
	row.add_child(value_label)
	if is_sfx:
		sfx_value_label = value_label
		slider.value_changed.connect(_on_sfx_changed)
	else:
		music_value_label = value_label
		slider.value_changed.connect(_on_music_changed)
	return slider


func _on_sfx_changed(value: float) -> void:
	sfx_value_label.text = "%d%%" % roundi(value)
	profile.call("set_sfx_volume", value)


func _on_music_changed(value: float) -> void:
	music_value_label.text = "%d%%" % roundi(value)
	profile.call("set_music_volume", value)


func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
