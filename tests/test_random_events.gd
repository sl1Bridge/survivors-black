extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const CRATE_SCENE: PackedScene = preload("res://scenes/breakable_crate.tscn")
const COMET_SCENE: PackedScene = preload("res://scenes/comet.tscn")
const INVENTORY_SCRIPT: Script = preload("res://scripts/inventory.gd")
const PISTOL_SCRIPT: Script = preload("res://scripts/pistol.gd")
const ABILITY_SCRIPT: Script = preload("res://scripts/ability.gd")
const PICKUP_MANAGER_SCRIPT: Script = preload("res://scripts/pickup_manager.gd")
const ENEMY_SPAWNER_SCRIPT: Script = preload("res://scripts/enemy_spawner.gd")
const RANDOM_EVENTS_SCRIPT: Script = preload("res://scripts/random_events.gd")

var failures := 0
var boss_defeat_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 900)
	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	root.add_child(player)
	await process_frame
	player.set_process(false)
	player.set_physics_process(false)
	player.call("configure_run", 100, 48.0)

	var enemies := Node2D.new()
	enemies.name = "TestEnemies"
	root.add_child(enemies)
	var projectiles := Node2D.new()
	projectiles.name = "TestProjectiles"
	root.add_child(projectiles)
	var pickup_manager: Node2D = PICKUP_MANAGER_SCRIPT.new() as Node2D
	pickup_manager.call("configure", player)
	root.add_child(pickup_manager)
	var spawner: Node2D = ENEMY_SPAWNER_SCRIPT.new() as Node2D
	spawner.call("configure", player, enemies, projectiles)
	root.add_child(spawner)
	spawner.set_process(false)
	var events: Node2D = RANDOM_EVENTS_SCRIPT.new() as Node2D
	events.call("configure", player, enemies, spawner, pickup_manager)
	root.add_child(events)
	events.set_process(false)
	events.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

	events.call("_process", 29.9)
	_check(events.get_child_count() == 0, "Comet should not spawn before thirty seconds")
	events.call("_process", 0.1)
	_check(events.get_child_count() == 1, "A comet should spawn at thirty seconds")
	var scheduled_comet: Node2D = events.get_child(0) as Node2D
	var center := get_root().size * 0.5
	var center_distance := float(
		scheduled_comet.call(
			"_distance_to_segment",
			center,
			scheduled_comet.get("start_position"),
			scheduled_comet.get("end_position")
		)
	)
	_check(center_distance <= 40.01, "Comet path should pass within forty pixels of arena center")

	var damaged_enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	damaged_enemy.add_to_group("enemies")
	damaged_enemy.call("setup", player)
	root.add_child(damaged_enemy)
	damaged_enemy.global_position = Vector2(150.0, 200.0)
	damaged_enemy.set_process(false)
	player.global_position = Vector2(300.0, 200.0)
	var test_comet: Node2D = COMET_SCENE.instantiate() as Node2D
	test_comet.call("configure", player, Vector2(0.0, 200.0), Vector2(400.0, 200.0))
	root.add_child(test_comet)
	test_comet.call("_process", 1.0)
	_check(int(player.get("current_health")) == 90, "Comet should deal ten contact damage to the player")
	_check(int(damaged_enemy.get("current_health")) == 20, "Comet should deal ten damage to an enemy it crosses")

	player.call("configure_run", 100, 48.0)
	player.call("take_damage", 5)
	player.global_position = Vector2(300.0, 200.0)
	pickup_manager.call("spawn_event_pickup", &"burger", player.global_position + Vector2(60.0, 0.0), 10)
	var burger: Node2D = pickup_manager.get_child(pickup_manager.get_child_count() - 1) as Node2D
	burger.call("_process", 0.1)
	_check(not bool(burger.get("is_collected")), "Burger should not be magnetized")
	_check(absf(burger.global_position.distance_to(player.global_position) - 60.0) < 0.01, "Burger should remain still outside touch distance")
	burger.global_position = player.global_position + Vector2(20.0, 0.0)
	burger.call("_process", 0.0)
	_check(int(player.get("current_health")) == 100, "Burger should restore ten health but not exceed maximum health")
	_check(burger.is_in_group("event_objects"), "Burger should count toward the event-object limit")
	await process_frame

	events.set("object_elapsed", 59.9)
	events.call("_process", 0.1)
	var spawned_objects := get_nodes_in_group("event_objects")
	var first_object: Node2D
	if not spawned_objects.is_empty():
		first_object = spawned_objects[0] as Node2D
	_check(is_instance_valid(first_object), "A random object should spawn at one minute")
	var second_object: Node2D = events.call("_spawn_random_object") as Node2D
	_check(is_instance_valid(second_object), "Random event should allow two active objects")
	_check(get_nodes_in_group("event_objects").size() == 2, "Random event should cap active objects at two")
	_check(events.call("_spawn_random_object") == null, "Random event should not exceed the two-object cap")
	for event_object in get_nodes_in_group("event_objects"):
		event_object.queue_free()
	await process_frame

	for enemy in get_nodes_in_group("enemies"):
		enemy.global_position = player.global_position + Vector2(500.0, 0.0)
		enemy.set_process(false)
	var inventory: Node = INVENTORY_SCRIPT.new()
	root.add_child(inventory)
	var pistol: Node = PISTOL_SCRIPT.new()
	pistol.call("configure", player, inventory, projectiles)
	root.add_child(pistol)
	pistol.set_process(false)
	var crate: Node2D = CRATE_SCENE.instantiate() as Node2D
	crate.connect("destroyed", Callable(pickup_manager, "handle_crate_destroyed"))
	pickup_manager.add_child(crate)
	crate.global_position = player.global_position + Vector2(120.0, 0.0)
	_check(pistol.call("_find_nearest_target") == crate, "Pistol should target a crate when no enemy is in range")
	for _hit in range(3):
		pistol.set("cooldown", 0.0)
		pistol.call("_process", 0.016)
		var projectile: Node2D = projectiles.get_child(projectiles.get_child_count() - 1) as Node2D
		projectile.global_position = crate.global_position
		projectile.call("_process", 0.0)
	_check(bool(crate.get("is_destroyed")), "Three base pistol hits should break a thirty-health crate")
	var crate_drop_found := false
	for pickup in pickup_manager.get_children():
		if pickup.get("kind") == &"gold" or pickup.get("kind") == &"xp":
			crate_drop_found = true
	_check(crate_drop_found, "Destroyed crate should drop either gold or experience")

	var blockers: Array[Node2D] = []
	var blocker_count := maxi(0, 30 - get_nodes_in_group("enemies").size())
	for _index in range(blocker_count):
		var blocker := Node2D.new()
		blocker.add_to_group("enemies")
		root.add_child(blocker)
		blockers.append(blocker)
	events.set("boss_elapsed", 179.0)
	events.call("_process", 1.0)
	_check(get_nodes_in_group("bosses").is_empty(), "Boss should respect the thirty-enemy limit")
	for blocker in blockers:
		blocker.queue_free()
	await process_frame
	events.call("_process", 0.01)
	var bosses := get_nodes_in_group("bosses")
	_check(bosses.size() == 1, "Boss should spawn when the run reaches three minutes")
	if bosses.size() == 1:
		var boss: Node2D = bosses[0] as Node2D
		boss.set_process(false)
		boss.global_position = player.global_position + Vector2(100.0, 0.0)
		_check(int(boss.get("current_health")) == 300, "Boss should have three hundred health")
		var ability: Node2D = ABILITY_SCRIPT.new() as Node2D
		ability.call("configure", player)
		root.add_child(ability)
		ability.set_process(false)
		ability.call("activate")
		_check(float(boss.get("knockback_remaining")) > 0.0, "Player ability should knock back the boss")
		boss.call("_process", 2.5)
		_check(absf(float(boss.call("get_summon_progress")) - 0.5) < 0.01, "Boss summon bar should show half charge after two and a half seconds")
		var enemies_before_summon := get_nodes_in_group("enemies").size()
		boss.call("_process", 2.5)
		_check(get_nodes_in_group("enemies").size() == enemies_before_summon + 2, "Boss should summon two regular enemies every five seconds")
		_check(float(boss.call("get_summon_progress")) == 0.0, "Boss summon bar should reset after automatic summoning")
		boss.call("take_damage", 300)
	_check(boss_defeat_count == 1, "Defeating the boss should emit the victory event")

	if failures > 0:
		push_error("%d random-event test(s) failed" % failures)
		quit(1)
	else:
		print("Random-event tests passed.")
		quit(0)


func _on_boss_defeated() -> void:
	boss_defeat_count += 1


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
