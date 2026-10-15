extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SPAWNER_SCRIPT: Script = preload("res://scripts/enemy_spawner.gd")
const INVENTORY_SCRIPT: Script = preload("res://scripts/inventory.gd")
const PISTOL_SCRIPT: Script = preload("res://scripts/pistol.gd")
const PICKUP_MANAGER_SCRIPT: Script = preload("res://scripts/pickup_manager.gd")
const PROGRESSION_SCRIPT: Script = preload("res://scripts/progression.gd")
const HUD_SCRIPT: Script = preload("res://scripts/hud.gd")
const ABILITY_SCRIPT: Script = preload("res://scripts/ability.gd")
const RANDOM_EVENTS_SCRIPT: Script = preload("res://scripts/random_events.gd")

var run_finished := false
var profile: Node
var pickups: Node2D
var hud: CanvasLayer
var random_events: Node2D


func configure_profile(profile_node: Node) -> void:
	profile = profile_node


func _ready() -> void:
	if not is_instance_valid(profile):
		profile = get_node("/root/GameProfile")
	profile.call("begin_run")
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)

	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	player.name = "Player"
	player.call("configure_run", profile.call("get_max_health"), profile.call("get_pickup_radius"))
	player.add_to_group("player")
	add_child(player)

	var inventory: Node = INVENTORY_SCRIPT.new()
	inventory.name = "Inventory"
	add_child(inventory)

	var progression: Node = PROGRESSION_SCRIPT.new()
	progression.name = "Progression"
	progression.call("configure", inventory)
	add_child(progression)

	pickups = PICKUP_MANAGER_SCRIPT.new() as Node2D
	pickups.name = "PickupManager"
	pickups.call("configure", player)
	add_child(pickups)
	pickups.connect("experience_collected", Callable(progression, "add_xp"))
	pickups.connect("chest_collected", Callable(progression, "request_chest_choice"))

	var spawner: Node2D = ENEMY_SPAWNER_SCRIPT.new() as Node2D
	spawner.name = "EnemySpawner"
	spawner.call("configure", player, enemies, projectiles)
	spawner.connect("enemy_defeated", Callable(pickups, "handle_enemy_defeated"))
	add_child(spawner)

	random_events = RANDOM_EVENTS_SCRIPT.new() as Node2D
	random_events.name = "RandomEvents"
	random_events.call("configure", player, enemies, spawner, pickups)
	add_child(random_events)
	random_events.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

	var pistol: Node = PISTOL_SCRIPT.new()
	pistol.name = "Pistol"
	pistol.call("configure", player, inventory, projectiles)
	add_child(pistol)

	var ability: Node2D = ABILITY_SCRIPT.new() as Node2D
	ability.name = "Ability"
	ability.call("configure", player)
	add_child(ability)

	hud = HUD_SCRIPT.new() as CanvasLayer
	hud.name = "HUD"
	hud.call("configure", player, inventory, pickups, progression, ability, profile)
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.connect("return_to_menu_pressed", Callable(self, "_return_to_menu"))
	hud.connect("surrender_pressed", Callable(self, "_on_surrender_pressed"))

	player.connect("died", Callable(self, "_on_player_died"))


func _on_player_died() -> void:
	_finish_run()


func _on_surrender_pressed() -> void:
	_finish_run()


func _on_boss_defeated() -> void:
	_finish_run(true)


func _finish_run(is_victory: bool = false) -> void:
	if run_finished:
		return
	run_finished = true
	var run_gold := int(pickups.get("total_gold"))
	profile.call("finish_run", run_gold)
	get_tree().paused = true
	hud.call("show_run_finished", run_gold, is_victory)


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
