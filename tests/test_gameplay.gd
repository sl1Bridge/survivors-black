extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/pickup.tscn")
const INVENTORY_SCRIPT: Script = preload("res://scripts/inventory.gd")
const PISTOL_SCRIPT: Script = preload("res://scripts/pistol.gd")
const PICKUP_MANAGER_SCRIPT: Script = preload("res://scripts/pickup_manager.gd")
const PROGRESSION_SCRIPT: Script = preload("res://scripts/progression.gd")
const ENEMY_SPAWNER_SCRIPT: Script = preload("res://scripts/enemy_spawner.gd")
const HUD_SCRIPT: Script = preload("res://scripts/hud.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 900)
	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	root.add_child(player)
	await process_frame

	var magnet_pickup: Node2D = PICKUP_SCENE.instantiate() as Node2D
	magnet_pickup.call("configure", &"xp", 1, player)
	magnet_pickup.global_position = player.global_position + Vector2(60.0, 0.0)
	root.add_child(magnet_pickup)
	magnet_pickup.call("_process", 0.1)
	_check(absf(magnet_pickup.global_position.distance_to(player.global_position) - 60.0) < 0.01, "Pickup outside the magnetic radius should remain still")
	player.call("configure_run", 120, 80.0)
	_check(int(player.get("max_health")) == 120, "Permanent health bonus should set next-run maximum health")
	_check(int(player.get("current_health")) == 120, "Player should start a run at upgraded maximum health")
	magnet_pickup.call("_process", 0.05)
	_check(magnet_pickup.global_position.distance_to(player.global_position) < 60.0, "Pickup should move toward the player inside the upgraded radius")
	magnet_pickup.call("_process", 0.2)
	_check(bool(magnet_pickup.get("is_collected")), "Magnetized pickup should be collected on contact")
	player.call("configure_run", 100, 80.0)

	var inventory: Node = INVENTORY_SCRIPT.new()
	root.add_child(inventory)
	var progression: Node = PROGRESSION_SCRIPT.new()
	progression.call("configure", inventory)
	root.add_child(progression)
	var pickup_manager: Node2D = PICKUP_MANAGER_SCRIPT.new() as Node2D
	pickup_manager.call("configure", player)
	root.add_child(pickup_manager)
	pickup_manager.connect("experience_collected", Callable(progression, "add_xp"))
	var hud: CanvasLayer = HUD_SCRIPT.new() as CanvasLayer
	hud.call("configure", player, inventory, pickup_manager, progression)
	root.add_child(hud)
	await process_frame
	_check(hud.get("slot_labels").size() == 4, "HUD should display four inventory slots")

	var projectile_container := Node2D.new()
	root.add_child(projectile_container)
	var pistol: Node = PISTOL_SCRIPT.new()
	pistol.call("configure", player, inventory, projectile_container)
	root.add_child(pistol)
	var outside_enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	outside_enemy.add_to_group("enemies")
	outside_enemy.call("setup", player)
	outside_enemy.position = player.position + Vector2(300.0, 0.0)
	root.add_child(outside_enemy)
	pistol.call("_process", 0.016)
	_check(projectile_container.get_child_count() == 0, "Pistol should not fire at an enemy outside its range")

	var enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	enemy.add_to_group("enemies")
	enemy.call("setup", player)
	enemy.position = player.position + Vector2(120.0, 0.0)
	enemy.connect("defeated", Callable(pickup_manager, "spawn_enemy_drops"))
	root.add_child(enemy)
	var farther_enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	farther_enemy.add_to_group("enemies")
	farther_enemy.call("setup", player)
	farther_enemy.position = player.position + Vector2(180.0, 0.0)
	root.add_child(farther_enemy)
	pistol.call("_process", 0.016)
	_check(projectile_container.get_child_count() == 1, "Pistol should fire at an enemy in range")
	var projectile: Node2D = projectile_container.get_child(0) as Node2D
	_check(projectile.get("target") == enemy, "Pistol should select the nearest in-range enemy")
	var starting_distance := projectile.global_position.distance_to(enemy.global_position)
	projectile.call("_process", 0.1)
	_check(
		projectile.global_position.distance_to(enemy.global_position) < starting_distance,
		"Homing projectile should move toward its selected target"
	)
	projectile.global_position = enemy.global_position - Vector2(10.0, 0.0)
	projectile.call("_process", 0.1)
	_check(int(enemy.get("current_health")) == 20, "Homing projectile should hit its target")
	enemy.call("take_damage", 20)
	_check(bool(enemy.get("is_defeated")), "Enemy should be defeated when its health reaches zero")
	_check(pickup_manager.get_child_count() == 2, "Enemy defeat should create XP and gold pickups")
	player.global_position = enemy.global_position
	for pickup in pickup_manager.get_children():
		pickup.call("_process", 0.0)
	_check(int(pickup_manager.get("total_gold")) == 1, "Touching a gold drop should add one gold")
	_check(int(progression.get("current_xp")) == 1, "Touching an XP drop should add one XP")
	_check(str(hud.get("gold_label").text) == "Золото: 1", "HUD should display collected gold")

	var chasing_enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	chasing_enemy.call("setup", player)
	chasing_enemy.position = player.position + Vector2(300.0, 0.0)
	root.add_child(chasing_enemy)
	chasing_enemy.call("_process", 0.25)
	_check(
		absf(chasing_enemy.global_position.distance_to(player.global_position) - 250.0) < 0.01,
		"Enemy should move toward the player at its approved speed"
	)
	chasing_enemy.position = player.position + Vector2(20.0, 0.0)
	chasing_enemy.call("_process", 0.016)
	_check(int(player.get("current_health")) == 90, "Touching an enemy should damage the player")
	chasing_enemy.call("_process", 0.016)
	_check(int(player.get("current_health")) == 90, "Contact damage should respect the global cooldown")
	player.call("_process", 1.0)
	chasing_enemy.call("_process", 0.016)
	_check(int(player.get("current_health")) == 80, "Contact damage should resume after its cooldown")

	var enemy_container := Node2D.new()
	root.add_child(enemy_container)
	var spawner: Node2D = ENEMY_SPAWNER_SCRIPT.new() as Node2D
	spawner.call("configure", player, enemy_container)
	root.add_child(spawner)
	spawner.set_process(false)
	spawner.call("_process", 3.0)
	_check(enemy_container.get_child_count() == 1, "Spawner should create one enemy after its interval")
	var spawned_enemy: Node2D = enemy_container.get_child(0) as Node2D
	var viewport_size: Vector2 = player.get_viewport_rect().size
	var spawn_position := spawned_enemy.position
	var at_viewport_edge := (
		absf(spawn_position.x - 14.0) < 0.01
		or absf(spawn_position.x - (viewport_size.x - 14.0)) < 0.01
		or absf(spawn_position.y - 14.0) < 0.01
		or absf(spawn_position.y - (viewport_size.y - 14.0)) < 0.01
	)
	_check(at_viewport_edge, "Enemy should spawn at the viewport edge")
	for _index in range(40):
		spawner.call("_spawn_enemy")
	_check(get_nodes_in_group("enemies").size() <= 30, "Spawner should cap the number of active enemies")

	progression.call("add_xp", 4)
	_check(int(progression.get("current_level")) == 2, "Five XP should start the first level-up")
	_check(bool(progression.get("awaiting_upgrade_choice")), "Level-up should wait for an upgrade choice")
	_check(_tree_is_paused(), "Level-up should pause the game")
	_check(bool(hud.get("upgrade_overlay").visible), "HUD should show upgrade choices on level-up")
	var upgrade_panel: Control = hud.get("upgrade_overlay").get_child(0) as Control
	var choices: HBoxContainer = upgrade_panel.get_child(0).get_child(1) as HBoxContainer
	_check(choices.get_child_count() == 3, "Level-up HUD should show three choices")
	var first_choice: Button = choices.get_child(0) as Button
	var second_choice: Button = choices.get_child(1) as Button
	var third_choice: Button = choices.get_child(2) as Button
	_check(
		first_choice.text == second_choice.text and second_choice.text == third_choice.text,
		"All level-up choices should be identical"
	)
	progression.call("choose_pistol_upgrade")
	_check(int(inventory.get("pistol_level")) == 2, "Choosing the upgrade should raise pistol level")
	_check(int(inventory.get("pistol_damage")) == 15, "Pistol upgrade should add five damage")
	_check(absf(float(inventory.get("pistol_fire_rate")) - 1.25) < 0.001, "Pistol upgrade should increase fire rate by 25 percent")
	_check(not _tree_is_paused(), "Choosing an upgrade should resume the game")
	_check(not bool(hud.get("upgrade_overlay").visible), "HUD should hide upgrade choices after selection")

	player.call("_process", 1.0)
	player.call("take_contact_damage", 100)
	_check(bool(player.get("is_dead")), "Player should die when health reaches zero")
	_check(int(player.get("current_health")) == 0, "Player health should not drop below zero")
	_check(bool(hud.get("game_over_overlay").visible), "HUD should show the end-of-run screen on death")

	if failures > 0:
		push_error("%d gameplay test(s) failed" % failures)
		quit(1)
	else:
		print("Gameplay system tests passed.")
		quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)


func _tree_is_paused() -> bool:
	return paused
