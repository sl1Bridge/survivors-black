extends Control

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const MAX_NODES := 5

var gold_label: Label
var health_summary: Label
var pickup_summary: Label
var health_buttons: Array[Button] = []
var pickup_buttons: Array[Button] = []
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
	content.custom_minimum_size = Vector2(800.0, 0.0)
	panel.add_child(content)
	var title := Label.new()
	title.text = "Постоянные улучшения"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(gold_label)
	var branches := HBoxContainer.new()
	branches.add_child(_build_branch(
		"Здоровье",
		"+20 к максимальному здоровью за узел",
		&"health",
		health_buttons
	))
	branches.add_child(_build_branch(
		"Радиус подбора",
		"+32 px к магнитному радиусу за узел",
		&"pickup_radius",
		pickup_buttons
	))
	content.add_child(branches)
	health_summary = Label.new()
	pickup_summary = Label.new()
	health_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pickup_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(health_summary)
	content.add_child(pickup_summary)
	var back_button := Button.new()
	back_button.text = "Назад"
	back_button.pressed.connect(_return_to_menu)
	content.add_child(back_button)
	profile.connect("profile_changed", Callable(self, "_refresh"))
	_refresh()


func _build_branch(title_text: String, description: String, kind: StringName, buttons: Array[Button]) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var detail := Label.new()
	detail.text = description
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(330.0, 44.0)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(detail)
	for index in range(MAX_NODES):
		var row := HBoxContainer.new()
		content.add_child(row)
		var node_label := Label.new()
		node_label.text = "Узел %d" % (index + 1)
		node_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(node_label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(150.0, 36.0)
		button.pressed.connect(_purchase_upgrade.bind(kind))
		row.add_child(button)
		buttons.append(button)
	return panel


func _refresh() -> void:
	gold_label.text = "Золото: %d" % int(profile.get("banked_gold"))
	health_summary.text = "Максимальное здоровье в следующем забеге: %d" % int(profile.call("get_max_health"))
	pickup_summary.text = "Радиус подбора: %d px" % roundi(float(profile.call("get_pickup_radius")))
	_update_branch(&"health", health_buttons)
	_update_branch(&"pickup_radius", pickup_buttons)


func _update_branch(kind: StringName, buttons: Array[Button]) -> void:
	var level := int(profile.call("get_upgrade_level", kind))
	for index in range(buttons.size()):
		var button := buttons[index]
		if index < level:
			button.text = "Куплено"
			button.disabled = true
		elif index == level and level < MAX_NODES:
			var cost := int(profile.call("get_upgrade_cost", kind))
			button.text = "Купить за %d" % cost
			button.disabled = int(profile.get("banked_gold")) < cost
		else:
			button.text = "Максимум" if level >= MAX_NODES else "Закрыто"
			button.disabled = true


func _purchase_upgrade(kind: StringName) -> void:
	profile.call("purchase_upgrade", kind)
	_refresh()


func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
