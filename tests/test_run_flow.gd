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
	var hud: Node = run.get_node("HUD")
	var random_events: Node = run.get_node("RandomEvents")
	_check(str(hud.get("ability_label").text) == "Готово", "HUD should show that the ability is ready")
	_check(int(player.get("max_health")) == 140, "Run should apply permanent maximum-health upgrades")
	_check(absf(float(player.get("pickup_radius")) - 80.0) < 0.01, "Run should apply permanent pickup-radius upgrades")

	run.get_node("PickupManager").set("total_gold", 3)
	Input.action_press("pause_game")
	hud.call("_process", 0.016)
	Input.action_release("pause_game")
	_check(paused, "Pause action should pause the run")
	_check(bool(hud.get("pause_overlay").visible), "Pause action should open the pause menu")
	var comet_clock_before_pause := float(random_events.get("comet_elapsed"))
	await process_frame
	_check(absf(float(random_events.get("comet_elapsed")) - comet_clock_before_pause) < 0.00001, "Event timers should stop while paused")
	var pause_buttons: Array = hud.get("pause_overlay").find_children("*", "Button", true, false)
	_check(pause_buttons.size() == 2, "Pause menu should have surrender and close buttons")
	_check(pause_buttons[0].text == "Сдаться" and pause_buttons[1].text == "Закрыть", "Pause menu actions should be in the expected order")
	hud.call("_close_pause_menu")
	_check(not paused, "Closing the pause menu should resume the run")
	Input.action_press("pause_game")
	hud.call("_process", 0.016)
	Input.action_release("pause_game")
	_check(paused, "Pause action should reopen the pause menu")
	Input.action_press("pause_game")
	hud.call("_process", 0.016)
	Input.action_release("pause_game")
	_check(not paused, "Pause action should close the pause menu when pressed again")
	Input.action_press("pause_game")
	hud.call("_process", 0.016)
	Input.action_release("pause_game")
	hud.call("_on_surrender_pressed")
	_check(int(profile.get("banked_gold")) == 3, "Surrender should bank run gold")
	_check(paused, "Surrender should end and pause the run")
	_check(bool(hud.get("game_over_overlay").visible), "Surrender should show the result screen")
	run.call("_on_player_died")
	_check(int(profile.get("banked_gold")) == 3, "Repeated death callback should not bank gold twice")

	paused = false
	run.queue_free()
	await process_frame
	var death_run: Node2D = RUN_SCENE.instantiate() as Node2D
	death_run.call("configure_profile", profile)
	root.add_child(death_run)
	await process_frame
	death_run.get_node("PickupManager").set("total_gold", 2)
	death_run.get_node("Player").call("take_damage", 200)
	_check(int(profile.get("banked_gold")) == 5, "Player death should bank the run's gold")
	_check(bool(death_run.get_node("HUD").get("game_over_overlay").visible), "Player death should show the result screen")
	paused = false
	death_run.queue_free()
	await process_frame
	var victory_run: Node2D = RUN_SCENE.instantiate() as Node2D
	victory_run.call("configure_profile", profile)
	root.add_child(victory_run)
	await process_frame
	victory_run.get_node("PickupManager").set("total_gold", 4)
	victory_run.get_node("RandomEvents").emit_signal("boss_defeated")
	_check(int(profile.get("banked_gold")) == 9, "Boss victory should bank run gold once")
	_check(str(victory_run.get_node("HUD").get("game_over_title").text) == "ПОБЕДА!", "Boss defeat should show the victory result")
	_check(paused, "Boss victory should end and pause the run")
	paused = false
	victory_run.queue_free()
	await process_frame
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
