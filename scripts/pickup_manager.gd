extends Node2D

signal gold_changed(total_gold: int)
signal experience_collected(amount: int)

const PICKUP_SCENE: PackedScene = preload("res://scenes/pickup.tscn")

var player: Node2D
var total_gold := 0


func configure(player_node: Node2D) -> void:
	player = player_node


func spawn_enemy_drops(world_position: Vector2) -> void:
	_spawn_pickup(&"xp", world_position + Vector2(-6.0, 0.0))
	_spawn_pickup(&"gold", world_position + Vector2(6.0, 0.0))


func _spawn_pickup(kind: StringName, world_position: Vector2) -> void:
	var pickup: Node2D = PICKUP_SCENE.instantiate() as Node2D
	pickup.call("configure", kind, 1, player)
	pickup.global_position = world_position
	pickup.connect("collected", Callable(self, "_on_pickup_collected"))
	add_child(pickup)


func _on_pickup_collected(kind: StringName, amount: int) -> void:
	if kind == &"xp":
		experience_collected.emit(amount)
	else:
		total_gold += amount
		gold_changed.emit(total_gold)
