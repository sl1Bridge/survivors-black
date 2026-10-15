extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SPAWNER_SCRIPT: Script = preload("res://scripts/enemy_spawner.gd")
const INVENTORY_SCRIPT: Script = preload("res://scripts/inventory.gd")
const PISTOL_SCRIPT: Script = preload("res://scripts/pistol.gd")
const PICKUP_MANAGER_SCRIPT: Script = preload("res://scripts/pickup_manager.gd")
const PROGRESSION_SCRIPT: Script = preload("res://scripts/progression.gd")
const HUD_SCRIPT: Script = preload("res://scripts/hud.gd")


func _ready() -> void:
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)

	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	player.name = "Player"
	player.add_to_group("player")
	add_child(player)

	var inventory: Node = INVENTORY_SCRIPT.new()
	inventory.name = "Inventory"
	add_child(inventory)

	var progression: Node = PROGRESSION_SCRIPT.new()
	progression.name = "Progression"
	progression.call("configure", inventory)
	add_child(progression)

	var pickups: Node2D = PICKUP_MANAGER_SCRIPT.new() as Node2D
	pickups.name = "PickupManager"
	pickups.call("configure", player)
	add_child(pickups)
	pickups.connect("experience_collected", Callable(progression, "add_xp"))

	var spawner: Node2D = ENEMY_SPAWNER_SCRIPT.new() as Node2D
	spawner.name = "EnemySpawner"
	spawner.call("configure", player, enemies)
	spawner.connect("enemy_defeated", Callable(pickups, "spawn_enemy_drops"))
	add_child(spawner)

	var pistol: Node = PISTOL_SCRIPT.new()
	pistol.name = "Pistol"
	pistol.call("configure", player, inventory, projectiles)
	add_child(pistol)

	var hud: CanvasLayer = HUD_SCRIPT.new() as CanvasLayer
	hud.name = "HUD"
	hud.call("configure", player, inventory, pickups, progression)
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)

	player.connect("died", Callable(self, "_on_player_died"))


func _on_player_died() -> void:
	get_tree().paused = true
