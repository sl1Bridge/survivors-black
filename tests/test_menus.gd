extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main_menu.tscn")
const SETTINGS_MENU_SCENE: PackedScene = preload("res://scenes/settings_menu.tscn")
const AUDIO_SETTINGS_SCENE: PackedScene = preload("res://scenes/audio_settings.tscn")
const CONTROLS_MENU_SCENE: PackedScene = preload("res://scenes/controls_menu.tscn")
const UPGRADES_MENU_SCENE: PackedScene = preload("res://scenes/upgrades_menu.tscn")
const PROFILE_SCRIPT: Script = preload("res://scripts/game_profile.gd")
const TEST_SAVE_PATH := "user://test_survivors_black_menus.cfg"

var failures := 0
var profile: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	profile = PROFILE_SCRIPT.new()
	profile.name = "TestProfile"
	profile.set("profile_path", TEST_SAVE_PATH)
	root.add_child(profile)
	await process_frame
	profile.call("begin_run")
	profile.call("finish_run", 100)

	var main_menu: Control = MAIN_MENU_SCENE.instantiate() as Control
	main_menu.call("configure", profile)
	root.add_child(main_menu)
	await process_frame
	var menu_buttons := main_menu.find_children("*", "Button", true, false)
	var menu_labels: Array[String] = []
	for button in menu_buttons:
		menu_labels.append(button.text)
	var main_menu_labels := main_menu.find_children("*", "Label", true, false)
	var displayed_values: Array[String] = []
	for label in main_menu_labels:
		displayed_values.append(label.text)
	_check(menu_labels.has("Начать забег"), "Main menu should offer starting a run")
	_check(menu_labels.has("Выход из игры"), "Main menu should offer exiting the game")
	_check(menu_labels.has("Улучшения"), "Main menu should offer upgrades")
	_check(menu_labels.has("Настройки"), "Main menu should offer settings")
	_check(displayed_values.has("Золото: 100"), "Main menu should show banked gold")
	_check(
		menu_labels == ["Начать забег", "Улучшения", "Настройки", "Выход из игры"],
		"Main menu options should follow the expected order"
	)
	main_menu.queue_free()
	await process_frame

	var settings_menu: Control = SETTINGS_MENU_SCENE.instantiate() as Control
	root.add_child(settings_menu)
	await process_frame
	var settings_buttons := settings_menu.find_children("*", "Button", true, false)
	var settings_labels: Array[String] = []
	for button in settings_buttons:
		settings_labels.append(button.text)
	_check(settings_labels == ["Звук", "Управление", "Назад"], "Settings menu should contain sound, controls, and back")
	settings_menu.queue_free()
	await process_frame

	var audio_settings: Control = AUDIO_SETTINGS_SCENE.instantiate() as Control
	audio_settings.call("configure", profile)
	root.add_child(audio_settings)
	await process_frame
	var sliders := audio_settings.find_children("*", "HSlider", true, false)
	_check(sliders.size() == 2, "Settings should contain separate sound and music sliders")
	_check(
		absf(float(audio_settings.get("sfx_slider").value - float(profile.get("sfx_volume")))) < 0.01,
		"Sound slider should show the saved value"
	)
	_check(
		absf(float(audio_settings.get("music_slider").value - float(profile.get("music_volume")))) < 0.01,
		"Music slider should show the saved value"
	)
	audio_settings.get("sfx_slider").value = 42.0
	audio_settings.get("music_slider").value = 64.0
	_check(absf(float(profile.get("sfx_volume")) - 42.0) < 0.01, "SFX slider should update its separate volume")
	_check(absf(float(profile.get("music_volume")) - 64.0) < 0.01, "Music slider should update its separate volume")
	audio_settings.queue_free()
	await process_frame

	var controls_menu: Control = CONTROLS_MENU_SCENE.instantiate() as Control
	controls_menu.call("configure", profile)
	root.add_child(controls_menu)
	await process_frame
	_check(controls_menu.get("binding_labels").size() == 6, "Controls screen should expose all six game actions")
	controls_menu.call("_begin_rebind", &"ability")
	var rebind_event := InputEventKey.new()
	rebind_event.pressed = true
	rebind_event.physical_keycode = KEY_R
	controls_menu.call("_input", rebind_event)
	_check(int(profile.call("get_key_binding", &"ability")) == KEY_R, "Ability key should be rebindable")
	controls_menu.call("_begin_rebind", &"move_up")
	controls_menu.call("_input", rebind_event)
	_check(int(profile.call("get_key_binding", &"move_up")) == KEY_W, "Duplicate key bindings should be rejected")
	controls_menu.queue_free()
	await process_frame

	var upgrades_menu: Control = UPGRADES_MENU_SCENE.instantiate() as Control
	upgrades_menu.call("configure", profile)
	root.add_child(upgrades_menu)
	await process_frame
	_check(upgrades_menu.get("health_buttons").size() == 5, "Health branch should contain five nodes")
	_check(upgrades_menu.get("pickup_buttons").size() == 5, "Pickup branch should contain five nodes")
	var health_buttons: Array = upgrades_menu.get("health_buttons")
	_check(health_buttons[0].text == "Купить за 10", "First health node should show its cost")
	health_buttons[0].emit_signal("pressed")
	_check(int(profile.get("banked_gold")) == 90, "Buying health should deduct persistent gold")
	_check(int(profile.call("get_max_health")) == 120, "Bought health should raise next-run maximum health")
	var pickup_buttons: Array = upgrades_menu.get("pickup_buttons")
	pickup_buttons[0].emit_signal("pressed")
	_check(absf(float(profile.call("get_pickup_radius")) - 80.0) < 0.01, "Bought pickup upgrade should increase magnetic range")
	upgrades_menu.queue_free()
	await process_frame
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)

	if failures > 0:
		push_error("%d menu test(s) failed" % failures)
		quit(1)
	else:
		print("Menu tests passed.")
		quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
