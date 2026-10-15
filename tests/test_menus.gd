extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main_menu.tscn")
const SETTINGS_MENU_SCENE: PackedScene = preload("res://scenes/settings_menu.tscn")
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
	settings_menu.call("configure", profile)
	root.add_child(settings_menu)
	await process_frame
	var sliders := settings_menu.find_children("*", "HSlider", true, false)
	_check(sliders.size() == 2, "Settings should contain separate sound and music sliders")
	_check(
		absf(float(settings_menu.get("sfx_slider").value - float(profile.get("sfx_volume")))) < 0.01,
		"Sound slider should show the saved value"
	)
	_check(
		absf(float(settings_menu.get("music_slider").value - float(profile.get("music_volume")))) < 0.01,
		"Music slider should show the saved value"
	)
	settings_menu.get("sfx_slider").value = 42.0
	settings_menu.get("music_slider").value = 64.0
	_check(absf(float(profile.get("sfx_volume")) - 42.0) < 0.01, "SFX slider should update its separate volume")
	_check(absf(float(profile.get("music_volume")) - 64.0) < 0.01, "Music slider should update its separate volume")
	settings_menu.queue_free()
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
