extends Node2D

signal boss_defeated

const COMET_SCENE: PackedScene = preload("res://scenes/comet.tscn")
const CRATE_SCENE: PackedScene = preload("res://scenes/breakable_crate.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/boss.tscn")
const COMET_INTERVAL := 30.0
const OBJECT_INTERVAL := 60.0
const BOSS_INTERVAL := 180.0
const MAX_ACTIVE_OBJECTS := 2
const COMET_CENTER_RADIUS := 40.0
const OBJECT_SPAWN_MARGIN := 18.0

var player: Node2D
var enemies_container: Node2D
var enemy_spawner: Node
var pickup_manager: Node2D
var comet_elapsed := 0.0
var object_elapsed := 0.0
var boss_elapsed := 0.0
var rng := RandomNumberGenerator.new()


func configure(
	player_node: Node2D,
	enemies_node: Node2D,
	spawner_node: Node,
	pickups_node: Node2D
) -> void:
	player = player_node
	enemies_container = enemies_node
	enemy_spawner = spawner_node
	pickup_manager = pickups_node


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or player.get("is_dead"):
		return
	comet_elapsed += delta
	object_elapsed += delta
	boss_elapsed += delta
	if comet_elapsed >= COMET_INTERVAL:
		comet_elapsed = fmod(comet_elapsed, COMET_INTERVAL)
		_spawn_comet()
	if object_elapsed >= OBJECT_INTERVAL:
		object_elapsed = fmod(object_elapsed, OBJECT_INTERVAL)
		_spawn_random_object()
	if boss_elapsed >= BOSS_INTERVAL:
		if _has_active_boss():
			boss_elapsed = fmod(boss_elapsed, BOSS_INTERVAL)
		elif is_instance_valid(enemy_spawner) and enemy_spawner.call("can_spawn_enemy"):
			boss_elapsed = fmod(boss_elapsed, BOSS_INTERVAL)
			_spawn_boss_if_absent()
		else:
			boss_elapsed = BOSS_INTERVAL


func _spawn_comet() -> Node2D:
	if not is_instance_valid(player):
		return null
	var viewport_size := get_viewport_rect().size
	var center := viewport_size * 0.5
	var angle := rng.randf_range(0.0, TAU)
	var direction := Vector2.RIGHT.rotated(angle)
	var offset_angle := rng.randf_range(0.0, TAU)
	var offset_distance := sqrt(rng.randf()) * COMET_CENTER_RADIUS
	var closest_point := center + Vector2.RIGHT.rotated(offset_angle) * offset_distance
	var travel_distance := viewport_size.length() + COMET_CENTER_RADIUS
	var comet: Node2D = COMET_SCENE.instantiate() as Node2D
	comet.call("configure", player, closest_point - direction * travel_distance, closest_point + direction * travel_distance)
	add_child(comet)
	return comet


func _spawn_random_object() -> Node2D:
	if not is_instance_valid(pickup_manager):
		return null
	if get_tree().get_nodes_in_group("event_objects").size() >= MAX_ACTIVE_OBJECTS:
		return null
	var world_position := _random_arena_position()
	if rng.randi_range(0, 1) == 0:
		pickup_manager.call("spawn_event_pickup", &"burger", world_position, 10)
		return pickup_manager.get_child(pickup_manager.get_child_count() - 1) as Node2D
	var crate: Node2D = CRATE_SCENE.instantiate() as Node2D
	crate.connect("destroyed", Callable(pickup_manager, "handle_crate_destroyed"))
	pickup_manager.add_child(crate)
	crate.global_position = world_position
	return crate


func _spawn_boss_if_absent() -> Node2D:
	if (
		not is_instance_valid(enemies_container)
		or not is_instance_valid(enemy_spawner)
		or not enemy_spawner.call("can_spawn_enemy")
	):
		return null
	if _has_active_boss():
		return null
	var boss: Node2D = BOSS_SCENE.instantiate() as Node2D
	boss.call("configure", player, enemy_spawner)
	boss.connect("defeated", Callable(self, "_on_boss_defeated"))
	enemies_container.add_child(boss)
	boss.global_position = enemy_spawner.call("_random_edge_position", 24.0)
	boss.add_to_group("bosses")
	return boss


func _has_active_boss() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.is_in_group("bosses") and not enemy.is_queued_for_deletion():
			return true
	return false


func _random_arena_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var right := maxf(OBJECT_SPAWN_MARGIN, viewport_size.x - OBJECT_SPAWN_MARGIN)
	var bottom := maxf(OBJECT_SPAWN_MARGIN, viewport_size.y - OBJECT_SPAWN_MARGIN)
	return Vector2(
		rng.randf_range(OBJECT_SPAWN_MARGIN, right),
		rng.randf_range(OBJECT_SPAWN_MARGIN, bottom)
	)


func _on_boss_defeated() -> void:
	boss_defeated.emit()
