extends Control

const SETTINGS_MENU_PATH := "res://scenes/settings_menu.tscn"
const CONFIRM_SECONDS := 10.0

var profile: Node
var resolution_option: OptionButton
var fps_option: OptionButton
var confirmation_panel: VBoxContainer
var confirmation_label: Label
var pending_resolution := false
var previous_resolution := Vector2i.ZERO
var selected_resolution := Vector2i.ZERO
var confirmation_remaining := 0.0


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
	title.text = "Графика"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	_build_resolution_control(content)
	_build_fps_control(content)
	_build_confirmation(content)
	var back_button := Button.new()
	back_button.text = "Назад"
	back_button.pressed.connect(_return_to_settings)
	content.add_child(back_button)


func _process(delta: float) -> void:
	if not pending_resolution:
		return
	confirmation_remaining = maxf(0.0, confirmation_remaining - delta)
	confirmation_label.text = "Оставить это разрешение? Возврат через %d с" % ceili(confirmation_remaining)
	if confirmation_remaining <= 0.0:
		_revert_resolution()


func _build_resolution_control(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = "Разрешение окна"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	resolution_option = OptionButton.new()
	row.add_child(resolution_option)
	var resolutions: Array = profile.call("get_resolution_options")
	var current_resolution: Vector2i = profile.call("get_resolution")
	for resolution in resolutions:
		var size := resolution as Vector2i
		var index := resolution_option.item_count
		resolution_option.add_item("%d × %d" % [size.x, size.y])
		resolution_option.set_item_metadata(index, size)
		if size == current_resolution:
			resolution_option.select(index)
	resolution_option.item_selected.connect(_on_resolution_selected)


func _build_fps_control(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = "Ограничение FPS"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	fps_option = OptionButton.new()
	row.add_child(fps_option)
	var current_cap := int(profile.get("fps_cap"))
	var options: Array = profile.call("get_fps_cap_options")
	for cap in options:
		var fps_cap := int(cap)
		var index := fps_option.item_count
		fps_option.add_item("Без ограничения" if fps_cap == 0 else "%d FPS" % fps_cap)
		fps_option.set_item_metadata(index, fps_cap)
		if fps_cap == current_cap:
			fps_option.select(index)
	fps_option.item_selected.connect(_on_fps_selected)


func _build_confirmation(parent: VBoxContainer) -> void:
	confirmation_panel = VBoxContainer.new()
	confirmation_panel.visible = false
	parent.add_child(confirmation_panel)
	confirmation_label = Label.new()
	confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation_panel.add_child(confirmation_label)
	var buttons := HBoxContainer.new()
	confirmation_panel.add_child(buttons)
	var keep_button := Button.new()
	keep_button.text = "Оставить"
	keep_button.pressed.connect(_confirm_resolution)
	buttons.add_child(keep_button)
	var revert_button := Button.new()
	revert_button.text = "Вернуть"
	revert_button.pressed.connect(_revert_resolution)
	buttons.add_child(revert_button)


func _on_resolution_selected(index: int) -> void:
	if pending_resolution:
		return
	var requested: Vector2i = resolution_option.get_item_metadata(index)
	previous_resolution = DisplayServer.window_get_size()
	if requested == previous_resolution:
		return
	if not bool(profile.call("preview_resolution", requested)):
		_refresh_resolution_selection()
		return
	selected_resolution = requested
	pending_resolution = true
	confirmation_remaining = CONFIRM_SECONDS
	confirmation_panel.visible = true
	resolution_option.disabled = true
	_process(0.0)


func _on_fps_selected(index: int) -> void:
	var value := int(fps_option.get_item_metadata(index))
	profile.call("set_fps_cap", value)


func _confirm_resolution() -> void:
	if not pending_resolution:
		return
	if not bool(profile.call("commit_resolution", selected_resolution)):
		_revert_resolution()
		return
	_finish_resolution_confirmation()


func _revert_resolution() -> void:
	if not pending_resolution:
		return
	profile.call("preview_resolution", previous_resolution)
	_finish_resolution_confirmation()
	_refresh_resolution_selection()


func _finish_resolution_confirmation() -> void:
	pending_resolution = false
	confirmation_panel.visible = false
	resolution_option.disabled = false


func _refresh_resolution_selection() -> void:
	var saved_resolution: Vector2i = profile.call("get_resolution")
	for index in range(resolution_option.item_count):
		if resolution_option.get_item_metadata(index) == saved_resolution:
			resolution_option.select(index)
			return


func _return_to_settings() -> void:
	if pending_resolution:
		_revert_resolution()
	get_tree().change_scene_to_file(SETTINGS_MENU_PATH)
