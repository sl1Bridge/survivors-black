extends SceneTree

const RUN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PROFILE_SCRIPT: Script = preload("res://scripts/game_profile.gd")
const TEST_SAVE_PATH := "user://test_survivors_black_run.cfg"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 900)
	var profile: Node = PROFILE_SCRIPT.new()
	profile.name = "TestProfile"
	profile.set("profile_path", TEST_SAVE_PATH)
	root.add_child(profile)
	await process_frame
	profile.set("health_upgrade_level", 2)
	profile.set("pickup_radius_upgrade_level", 1)

	var run: Node2D = RUN_SCENE.instantiate() as Node2D
	run.call("configure_profile", profile)
	root.add_child(run)
	await process_frame
	var player: Node = run.get_node("Player")
	_check(int(player.get("max_health")) == 140, "Run should apply permanent maximum-health upgrades")
	_check(absf(float(player.get("pickup_radius")) - 80.0) < 0.01, "Run should apply permanent pickup-radius upgrades")

	run.get_node("PickupManager").set("total_gold", 3)
	player.call("take_contact_damage", 200)
	_check(bool(player.get("is_dead")), "Player death should end the run")
	_check(int(profile.get("banked_gold")) == 3, "Run gold should be banked on death")
	_check(paused, "Run should pause on death")
	_check(bool(run.get_node("HUD").get("game_over_overlay").visible), "Death should show the result screen")
	run.call("_on_player_died")
	_check(int(profile.get("banked_gold")) == 3, "Repeated death callback should not bank gold twice")

	paused = false
	run.queue_free()
	profile.queue_free()
	await process_frame
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)

	if failures > 0:
		push_error("%d run-flow test(s) failed" % failures)
		quit(1)
	else:
		print("Run-flow tests passed.")
		quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
