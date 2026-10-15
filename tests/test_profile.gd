extends SceneTree

const PROFILE_SCRIPT: Script = preload("res://scripts/game_profile.gd")
const TEST_SAVE_PATH := "user://test_survivors_black_profile.cfg"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_window_size := DisplayServer.window_get_size()
	var original_fps_cap := Engine.max_fps
	var profile: Node = PROFILE_SCRIPT.new()
	profile.set("profile_path", TEST_SAVE_PATH)
	root.add_child(profile)
	await process_frame

	profile.call("begin_run")
	profile.call("finish_run", 7)
	profile.call("finish_run", 7)
	_check(int(profile.get("banked_gold")) == 7, "Run gold should be banked only once")
	_check(int(profile.call("get_upgrade_cost", &"health")) == 10, "First health upgrade should cost ten gold")
	_check(not bool(profile.call("purchase_upgrade", &"health")), "Upgrade should be unavailable without enough gold")
	profile.call("begin_run")
	profile.call("finish_run", 13)
	_check(bool(profile.call("purchase_upgrade", &"health")), "Affordable health upgrade should be purchasable")
	_check(int(profile.call("get_max_health")) == 120, "Health upgrade should add twenty maximum health")
	_check(int(profile.get("banked_gold")) == 10, "Purchasing should deduct the cost")
	_check(not bool(profile.call("purchase_upgrade", &"unknown")), "Unknown upgrade type should not be purchasable")

	profile.set("banked_gold", 50)
	_check(bool(profile.call("purchase_upgrade", &"pickup_radius")), "Affordable pickup upgrade should be purchasable")
	_check(absf(float(profile.call("get_pickup_radius")) - 80.0) < 0.01, "First pickup upgrade should add thirty-two pixels")
	profile.call("set_sfx_volume", 35.0)
	profile.call("set_music_volume", 65.0)
	var resolution_to_save: Vector2i = profile.call("get_resolution")
	for candidate in profile.call("get_resolution_options"):
		if candidate != resolution_to_save:
			resolution_to_save = candidate
			break
	_check(bool(profile.call("commit_resolution", resolution_to_save)), "Supported resolution should be saved")
	_check(bool(profile.call("set_fps_cap", 120)), "FPS cap should be configurable")
	_check(bool(profile.call("set_key_binding", &"ability", KEY_R)), "Ability key binding should be changeable")
	_check(bool(profile.call("set_key_binding", &"pause_game", KEY_P)), "Pause key binding should be changeable")
	_check(not bool(profile.call("set_key_binding", &"move_up", KEY_R)), "Duplicate key binding should be rejected")
	_check(
		InputMap.action_get_events("ability")[0].physical_keycode == KEY_R,
		"Changing a binding should update the live InputMap"
	)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	var music_bus := AudioServer.get_bus_index("Music")
	_check(sfx_bus >= 0 and music_bus >= 0, "Separate SFX and Music buses should exist")
	_check(absf(AudioServer.get_bus_volume_db(sfx_bus) - linear_to_db(0.35)) < 0.01, "SFX slider should apply to the SFX bus")
	_check(absf(AudioServer.get_bus_volume_db(music_bus) - linear_to_db(0.65)) < 0.01, "Music slider should apply to the Music bus")

	var loaded_profile: Node = PROFILE_SCRIPT.new()
	loaded_profile.set("profile_path", TEST_SAVE_PATH)
	root.add_child(loaded_profile)
	await process_frame
	_check(int(loaded_profile.get("banked_gold")) == 40, "Banked gold should load from the local save")
	_check(int(loaded_profile.get("health_upgrade_level")) == 1, "Health upgrade should persist")
	_check(int(loaded_profile.get("pickup_radius_upgrade_level")) == 1, "Pickup upgrade should persist")
	_check(absf(float(loaded_profile.get("sfx_volume")) - 35.0) < 0.01, "SFX volume should persist")
	_check(absf(float(loaded_profile.get("music_volume")) - 65.0) < 0.01, "Music volume should persist")
	_check(loaded_profile.call("get_resolution") == resolution_to_save, "Resolution should persist")
	_check(int(loaded_profile.get("fps_cap")) == 120, "FPS cap should persist")
	_check(Engine.max_fps == 120, "Loaded FPS cap should apply to the engine")
	_check(int(loaded_profile.call("get_key_binding", &"ability")) == KEY_R, "Ability binding should persist")
	_check(int(loaded_profile.call("get_key_binding", &"pause_game")) == KEY_P, "Pause binding should persist")
	_check(
		InputMap.action_get_events("pause_game")[0].physical_keycode == KEY_P,
		"Loaded bindings should be applied to the live InputMap"
	)

	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
	DisplayServer.window_set_size(original_window_size)
	Engine.max_fps = original_fps_cap

	if failures > 0:
		push_error("%d profile test(s) failed" % failures)
		quit(1)
	else:
		print("Profile persistence tests passed.")
		quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
