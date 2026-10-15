extends Node

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const ATTACK_RANGE := 260.0
const PROJECTILE_SPEED := 180.0

var player: Node2D
var inventory: Node
var projectile_container: Node2D
var cooldown := 0.0


func configure(player_node: Node2D, inventory_node: Node, container: Node2D) -> void:
	player = player_node
	inventory = inventory_node
	projectile_container = container


func _process(delta: float) -> void:
	if not is_instance_valid(player) or player.get("is_dead"):
		return
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown > 0.0 or not is_instance_valid(projectile_container):
		return

	var target := _find_nearest_target()
	if target == null or player.global_position.distance_to(target.global_position) > ATTACK_RANGE:
		return

	var projectile: Node2D = PROJECTILE_SCENE.instantiate() as Node2D
	projectile.call(
		"configure",
		target,
		int(inventory.call("get_pistol_damage")),
		PROJECTILE_SPEED
	)
	projectile.global_position = player.global_position
	projectile_container.add_child(projectile)
	cooldown = 1.0 / float(inventory.call("get_pistol_fire_rate"))


func _find_nearest_target() -> Node2D:
	var enemy_target := _find_nearest_in_group("enemies")
	if is_instance_valid(enemy_target):
		return enemy_target
	return _find_nearest_in_group("breakable_crates")


func _find_nearest_in_group(group_name: StringName) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group(group_name):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		var candidate_node := candidate as Node2D
		var distance := player.global_position.distance_squared_to(candidate_node.global_position)
		if distance > ATTACK_RANGE * ATTACK_RANGE:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate_node
	return nearest
