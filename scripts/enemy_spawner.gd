extends Node2D

signal enemy_defeated(world_position: Vector2, is_elite: bool)

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const SPAWN_INTERVAL := 3.0
const MAX_ACTIVE_ENEMIES := 30
const SPAWN_MARGIN := 14.0
const ELITE_SPAWN_CHANCE := 0.05

var player: Node2D
var enemies_container: Node2D
var projectile_container: Node2D
var elapsed := 0.0
var rng := RandomNumberGenerator.new()


func configure(player_node: Node2D, container: Node2D, projectiles: Node2D = null) -> void:
	player = player_node
	enemies_container = container
	projectile_container = projectiles


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or player.get("is_dead"):
		return
	elapsed += delta
	if elapsed >= SPAWN_INTERVAL:
		elapsed -= SPAWN_INTERVAL
		_spawn_enemy()


func _spawn_enemy() -> void:
	var is_elite := rng.randf() < ELITE_SPAWN_CHANCE
	spawn_enemy_at(_random_edge_position(), is_elite)


func spawn_enemy_at(world_position: Vector2, is_elite: bool = false) -> Node2D:
	if not can_spawn_enemy():
		return null
	if not is_instance_valid(enemies_container):
		return null

	var enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	enemy.add_to_group("enemies")
	enemy.call("setup", player, is_elite, projectile_container)
	enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	enemies_container.add_child(enemy)
	enemy.global_position = world_position
	return enemy


func can_spawn_enemy() -> bool:
	return get_tree().get_nodes_in_group("enemies").size() < MAX_ACTIVE_ENEMIES


func _random_edge_position(margin: float = SPAWN_MARGIN) -> Vector2:
	var size := get_viewport_rect().size
	var right := maxf(margin, size.x - margin)
	var bottom := maxf(margin, size.y - margin)
	match rng.randi_range(0, 3):
		0:
			return Vector2(margin, rng.randf_range(margin, bottom))
		1:
			return Vector2(right, rng.randf_range(margin, bottom))
		2:
			return Vector2(rng.randf_range(margin, right), margin)
		_:
			return Vector2(rng.randf_range(margin, right), bottom)


func _on_enemy_defeated(world_position: Vector2, is_elite: bool) -> void:
	enemy_defeated.emit(world_position, is_elite)
