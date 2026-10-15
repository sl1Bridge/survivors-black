extends Node2D

signal collected(kind: StringName, amount: int)

const RADIUS := 7.0
const EXPERIENCE_COLOR := Color(0.35, 0.95, 1.0)
const GOLD_COLOR := Color(1.0, 0.78, 0.2)

var kind: StringName = &"xp"
var amount := 1
var player: Node2D
var is_collected := false


func configure(pickup_kind: StringName, pickup_amount: int, player_node: Node2D) -> void:
	kind = pickup_kind
	amount = pickup_amount
	player = player_node


func _process(_delta: float) -> void:
	if is_collected or not is_instance_valid(player) or player.get("is_dead"):
		return
	var collection_distance := float(player.call("get_collision_radius")) + RADIUS
	if global_position.distance_to(player.global_position) <= collection_distance:
		is_collected = true
		collected.emit(kind, amount)
		queue_free()


func _draw() -> void:
	var color := EXPERIENCE_COLOR if kind == &"xp" else GOLD_COLOR
	draw_circle(Vector2.ZERO, RADIUS, color)
