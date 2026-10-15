extends Node2D

signal gold_changed(total_gold: int)
signal experience_collected(amount: int)
signal chest_collected

const PICKUP_SCENE: PackedScene = preload("res://scenes/pickup.tscn")

var player: Node2D
var total_gold := 0


func configure(player_node: Node2D) -> void:
	player = player_node


func handle_enemy_defeated(world_position: Vector2, is_elite: bool) -> void:
	_spawn_pickup(&"xp", world_position + Vector2(-6.0, 0.0))
	_spawn_pickup(&"gold", world_position + Vector2(6.0, 0.0))
	if is_elite:
		_spawn_pickup(&"chest", world_position + Vector2(0.0, -20.0))


func spawn_event_pickup(kind: StringName, world_position: Vector2, amount: int = 1) -> void:
	_spawn_pickup(kind, world_position, amount)


func handle_crate_destroyed(world_position: Vector2, loot_kind: StringName) -> void:
	if loot_kind != &"xp" and loot_kind != &"gold":
		return
	_spawn_pickup(loot_kind, world_position)


func _spawn_pickup(kind: StringName, world_position: Vector2, amount: int = 1) -> void:
	var pickup: Node2D = PICKUP_SCENE.instantiate() as Node2D
	pickup.call("configure", kind, amount, player)
	pickup.global_position = world_position
	pickup.connect("collected", Callable(self, "_on_pickup_collected"))
	add_child(pickup)


func _on_pickup_collected(kind: StringName, amount: int) -> void:
	if kind == &"xp":
		experience_collected.emit(amount)
	elif kind == &"gold":
		total_gold += amount
		gold_changed.emit(total_gold)
	elif kind == &"chest":
		chest_collected.emit()
	elif kind == &"burger":
		if is_instance_valid(player):
			player.call("heal", amount)
