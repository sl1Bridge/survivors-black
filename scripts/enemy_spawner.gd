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
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ACTIVE_ENEMIES:
		return
	if not is_instance_valid(enemies_container):
		return

	var enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
	var is_elite := rng.randf() < ELITE_SPAWN_CHANCE
	enemy.add_to_group("enemies")
	enemy.position = _random_edge_position()
	enemy.call("setup", player, is_elite, projectile_container)
	enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	enemies_container.add_child(enemy)


func _random_edge_position() -> Vector2:
	var size := get_viewport_rect().size
	var right := maxf(SPAWN_MARGIN, size.x - SPAWN_MARGIN)
	var bottom := maxf(SPAWN_MARGIN, size.y - SPAWN_MARGIN)
	match rng.randi_range(0, 3):
		0:
			return Vector2(SPAWN_MARGIN, rng.randf_range(SPAWN_MARGIN, bottom))
		1:
			return Vector2(right, rng.randf_range(SPAWN_MARGIN, bottom))
		2:
			return Vector2(rng.randf_range(SPAWN_MARGIN, right), SPAWN_MARGIN)
		_:
			return Vector2(rng.randf_range(SPAWN_MARGIN, right), bottom)


func _on_enemy_defeated(world_position: Vector2, is_elite: bool) -> void:
	enemy_defeated.emit(world_position, is_elite)
