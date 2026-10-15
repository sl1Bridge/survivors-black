extends Control

const SETTINGS_MENU_PATH := "res://scenes/settings_menu.tscn"
const ACTIONS := [
	[&"move_up", "Движение вверх"],
	[&"move_left", "Движение влево"],
	[&"move_down", "Движение вниз"],
	[&"move_right", "Движение вправо"],
	[&"ability", "Способность"],
	[&"pause_game", "Пауза"],
]

var profile: Node
var binding_labels: Dictionary = {}
var rebind_buttons: Dictionary = {}
var status_label: Label
var cancel_button: Button
var waiting_action: StringName = &""


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
	content.custom_minimum_size = Vector2(560.0, 0.0)
	panel.add_child(content)
	var title := Label.new()
	title.text = "Управление"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	for action_data in ACTIONS:
		_add_binding_row(content, action_data[0], action_data[1])
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status_label)
	cancel_button = Button.new()
	cancel_button.text = "Отменить переназначение"
	cancel_button.visible = false
	cancel_button.pressed.connect(_cancel_rebind)
	content.add_child(cancel_button)
	var back_button := Button.new()
	back_button.text = "Назад"
	back_button.pressed.connect(_return_to_settings)
	content.add_child(back_button)
	profile.connect("profile_changed", Callable(self, "_refresh_bindings"))
	_refresh_bindings()


func _add_binding_row(parent: VBoxContainer, action: StringName, title: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := Label.new()
	name_label.text = title
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var binding_label := Label.new()
	binding_label.custom_minimum_size = Vector2(100.0, 0.0)
	binding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(binding_label)
	binding_labels[action] = binding_label
	var button := Button.new()
	button.text = "Назначить"
	button.pressed.connect(_begin_rebind.bind(action))
	row.add_child(button)
	rebind_buttons[action] = button


func _refresh_bindings() -> void:
	for action in binding_labels:
		var keycode := int(profile.call("get_key_binding", action))
		binding_labels[action].text = OS.get_keycode_string(keycode)
	for action in rebind_buttons:
		rebind_buttons[action].text = "Ожидание..." if action == waiting_action else "Назначить"


func _begin_rebind(action: StringName) -> void:
	waiting_action = action
	status_label.text = "Нажми новую клавишу для действия"
	cancel_button.visible = true
	_refresh_bindings()


func _input(event: InputEvent) -> void:
	if waiting_action == &"" or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	var keycode := int(key_event.physical_keycode)
	if keycode == 0:
		keycode = int(key_event.keycode)
	if bool(profile.call("set_key_binding", waiting_action, keycode)):
		status_label.text = "Клавиша назначена"
		waiting_action = &""
		cancel_button.visible = false
		_refresh_bindings()
	else:
		status_label.text = "Эта клавиша уже назначена другому действию"
	get_viewport().set_input_as_handled()


func _cancel_rebind() -> void:
	waiting_action = &""
	status_label.text = ""
	cancel_button.visible = false
	_refresh_bindings()


func _return_to_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_MENU_PATH)
