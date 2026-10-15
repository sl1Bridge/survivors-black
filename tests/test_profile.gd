extends SceneTree

const PROFILE_SCRIPT: Script = preload("res://scripts/game_profile.gd")
const TEST_SAVE_PATH := "user://test_survivors_black_profile.cfg"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
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

	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)

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
