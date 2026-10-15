extends Control

const RUN_SCENE_PATH := "res://scenes/main.tscn"
const UPGRADES_SCENE_PATH := "res://scenes/upgrades_menu.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/settings_menu.tscn"

var gold_label: Label
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
	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(340.0, 0.0)
	panel.add_child(menu)
	var title := Label.new()
	title.text = "Главное меню"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	menu.add_child(title)
	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(gold_label)
	_add_menu_button(menu, "Начать забег", _start_run)
	_add_menu_button(menu, "Улучшения", _open_upgrades)
	_add_menu_button(menu, "Настройки", _open_settings)
	_add_menu_button(menu, "Выход из игры", _exit_game)
	profile.connect("profile_changed", Callable(self, "_refresh_gold"))
	_refresh_gold()


func _add_menu_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320.0, 44.0)
	button.pressed.connect(callback)
	parent.add_child(button)


func _refresh_gold() -> void:
	gold_label.text = "Золото: %d" % int(profile.get("banked_gold"))


func _start_run() -> void:
	get_tree().change_scene_to_file(RUN_SCENE_PATH)


func _open_upgrades() -> void:
	get_tree().change_scene_to_file(UPGRADES_SCENE_PATH)


func _open_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)


func _exit_game() -> void:
	get_tree().quit()
