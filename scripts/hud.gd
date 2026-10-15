extends CanvasLayer

signal return_to_menu_pressed
signal surrender_pressed

var player: Node
var inventory: Node
var pickup_manager: Node
var progression: Node
var ability: Node
var profile: Node

var slot_labels: Array[Label] = []
var health_label: Label
var health_bar: ProgressBar
var gold_label: Label
var level_label: Label
var xp_bar: ProgressBar
var upgrade_overlay: ColorRect
var upgrade_title: Label
var game_over_overlay: ColorRect
var game_over_title: Label
var game_over_gold_label: Label
var pause_overlay: ColorRect
var ability_label: Label
var ability_bar: ProgressBar
var run_finished := false


func configure(
	player_node: Node,
	inventory_node: Node,
	pickup_node: Node,
	progression_node: Node,
	ability_node: Node = null,
	profile_node: Node = null
) -> void:
	player = player_node
	inventory = inventory_node
	pickup_manager = pickup_node
	progression = progression_node
	ability = ability_node
	profile = profile_node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_build_inventory(root)
	_build_health(root)
	_build_experience(root)
	_build_ability_indicator(root)
	_build_upgrade_overlay(root)
	_build_pause_overlay(root)
	_build_game_over_overlay(root)
	_connect_signals()
	_on_health_changed(int(player.call("get_current_health")), int(player.call("get_max_health")))
	_refresh_inventory()
	_on_gold_changed(int(pickup_manager.get("total_gold")))
	_on_xp_changed(
		int(progression.call("get_current_xp")),
		int(progression.call("get_required_xp")),
		int(progression.call("get_current_level"))
	)


func _process(_delta: float) -> void:
	if run_finished or upgrade_overlay.visible or game_over_overlay.visible:
		return
	if Input.is_action_just_pressed("pause_game"):
		if pause_overlay.visible:
			_close_pause_menu()
		else:
			_open_pause_menu()


func _build_inventory(root: Control) -> void:
	var inventory_panel := VBoxContainer.new()
	inventory_panel.position = Vector2(16.0, 16.0)
	root.add_child(inventory_panel)
	var slots_row := HBoxContainer.new()
	inventory_panel.add_child(slots_row)
	for _index in range(4):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(96.0, 54.0)
		slots_row.add_child(slot_panel)
		var slot_label := Label.new()
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_panel.add_child(slot_label)
		slot_labels.append(slot_label)
	gold_label = Label.new()
	inventory_panel.add_child(gold_label)


func _build_health(root: Control) -> void:
	var health_box := VBoxContainer.new()
	health_box.anchor_left = 1.0
	health_box.anchor_right = 1.0
	health_box.offset_left = -230.0
	health_box.offset_right = -16.0
	health_box.offset_top = 16.0
	health_box.offset_bottom = 76.0
	root.add_child(health_box)
	health_label = Label.new()
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_box.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_box.add_child(health_bar)


func _build_experience(root: Control) -> void:
	var experience_box := VBoxContainer.new()
	experience_box.anchor_left = 0.5
	experience_box.anchor_right = 0.5
	experience_box.anchor_top = 1.0
	experience_box.anchor_bottom = 1.0
	experience_box.offset_left = -260.0
	experience_box.offset_right = 260.0
	experience_box.offset_top = -62.0
	experience_box.offset_bottom = -12.0
	root.add_child(experience_box)
	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	experience_box.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	experience_box.add_child(xp_bar)


func _build_ability_indicator(root: Control) -> void:
	if not is_instance_valid(ability):
		return
	var panel := PanelContainer.new()
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 16.0
	panel.offset_right = 190.0
	panel.offset_top = -104.0
	panel.offset_bottom = -16.0
	root.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var icon_label := Label.new()
	var ability_key := "F"
	if is_instance_valid(profile):
		ability_key = OS.get_keycode_string(int(profile.call("get_key_binding", &"ability")))
	icon_label.text = "✦  Волна  [%s]" % ability_key
	content.add_child(icon_label)
	ability_label = Label.new()
	content.add_child(ability_label)
	ability_bar = ProgressBar.new()
	ability_bar.max_value = 30.0
	ability_bar.show_percentage = false
	content.add_child(ability_bar)
	ability.connect("cooldown_changed", Callable(self, "_on_ability_cooldown_changed"))
	_on_ability_cooldown_changed(float(ability.call("get_cooldown_remaining")))


func _build_upgrade_overlay(root: Control) -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrade_overlay.visible = false
	root.add_child(upgrade_overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -360.0
	panel.offset_right = 360.0
	panel.offset_top = -125.0
	panel.offset_bottom = 125.0
	upgrade_overlay.add_child(panel)

	var content := VBoxContainer.new()
	panel.add_child(content)
	upgrade_title = Label.new()
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(upgrade_title)
	var choices := HBoxContainer.new()
	content.add_child(choices)
	for _index in range(3):
		var button := Button.new()
		button.text = "Улучшить пистолет\n+5 урона, +25% скорострельности"
		button.custom_minimum_size = Vector2(210.0, 100.0)
		button.pressed.connect(_on_upgrade_button_pressed)
		choices.add_child(button)


func _build_pause_overlay(root: Control) -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	root.add_child(pause_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.text = "Пауза"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var surrender_button := Button.new()
	surrender_button.text = "Сдаться"
	surrender_button.pressed.connect(_on_surrender_pressed)
	content.add_child(surrender_button)
	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.pressed.connect(_close_pause_menu)
	content.add_child(close_button)


func _build_game_over_overlay(root: Control) -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.visible = false
	root.add_child(game_over_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	game_over_title = Label.new()
	game_over_title.text = "ЗАБЕГ ОКОНЧЕН"
	game_over_title.add_theme_font_size_override("font_size", 32)
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(game_over_title)
	game_over_gold_label = Label.new()
	game_over_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(game_over_gold_label)
	var menu_button := Button.new()
	menu_button.text = "В меню"
	menu_button.pressed.connect(_on_return_to_menu_pressed)
	content.add_child(menu_button)


func _connect_signals() -> void:
	player.connect("health_changed", Callable(self, "_on_health_changed"))
	player.connect("died", Callable(self, "_on_player_died"))
	inventory.connect("changed", Callable(self, "_refresh_inventory"))
	pickup_manager.connect("gold_changed", Callable(self, "_on_gold_changed"))
	progression.connect("xp_changed", Callable(self, "_on_xp_changed"))
	progression.connect("upgrade_choices_started", Callable(self, "_on_upgrade_choices_started"))
	progression.connect("upgrade_choices_finished", Callable(self, "_on_upgrade_choices_finished"))


func _refresh_inventory() -> void:
	for index in range(slot_labels.size()):
		slot_labels[index].text = str(inventory.call("get_slot_text", index))


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_label.text = "Здоровье: %d / %d" % [current_health, max_health]
	health_bar.max_value = max_health
	health_bar.value = current_health


func _on_gold_changed(total_gold: int) -> void:
	gold_label.text = "Золото: %d" % total_gold


func _on_xp_changed(current_xp: int, required_xp: int, current_level: int) -> void:
	level_label.text = "Уровень %d" % current_level
	xp_bar.max_value = required_xp
	xp_bar.value = current_xp


func _on_upgrade_choices_started(current_level: int, source: StringName) -> void:
	if source == &"chest":
		upgrade_title.text = "Сундук — выбери улучшение"
	else:
		upgrade_title.text = "Уровень %d — выбери улучшение" % current_level
	upgrade_overlay.visible = true


func _on_upgrade_choices_finished() -> void:
	upgrade_overlay.visible = false


func _on_upgrade_button_pressed() -> void:
	progression.call("choose_pistol_upgrade")


func _on_player_died() -> void:
	show_run_finished(int(pickup_manager.get("total_gold")))


func show_run_finished(run_gold: int, is_victory: bool = false) -> void:
	run_finished = true
	pause_overlay.visible = false
	game_over_title.text = "ПОБЕДА!" if is_victory else "ЗАБЕГ ОКОНЧЕН"
	game_over_gold_label.text = "Получено золота: %d" % run_gold
	game_over_overlay.visible = true


func _on_return_to_menu_pressed() -> void:
	return_to_menu_pressed.emit()


func _on_ability_cooldown_changed(seconds_remaining: float) -> void:
	if not is_instance_valid(ability_label) or not is_instance_valid(ability_bar):
		return
	if seconds_remaining <= 0.0:
		ability_label.text = "Готово"
		ability_bar.value = 30.0
	else:
		ability_label.text = "%d с" % ceili(seconds_remaining)
		ability_bar.value = 30.0 - seconds_remaining


func _open_pause_menu() -> void:
	pause_overlay.visible = true
	get_tree().paused = true


func _close_pause_menu() -> void:
	pause_overlay.visible = false
	get_tree().paused = false


func _on_surrender_pressed() -> void:
	pause_overlay.visible = false
	surrender_pressed.emit()
