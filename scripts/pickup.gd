extends Node2D

signal collected(kind: StringName, amount: int)

const RADIUS := 7.0
const MAGNET_SPEED := 360.0
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


func _ready() -> void:
	if kind == &"burger":
		add_to_group("event_objects")


func _process(delta: float) -> void:
	if is_collected or not is_instance_valid(player) or player.get("is_dead"):
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var touch_distance := float(player.call("get_collision_radius")) + RADIUS
	if distance <= touch_distance:
		_collect()
		return
	if (kind == &"xp" or kind == &"gold") and distance <= float(player.call("get_pickup_radius")) and distance > 0.0:
		global_position = global_position.move_toward(player.global_position, MAGNET_SPEED * delta)
		if global_position.distance_to(player.global_position) <= touch_distance:
			_collect()


func _collect() -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit(kind, amount)
	queue_free()


func _draw() -> void:
	if kind == &"chest":
		draw_rect(Rect2(-9.0, -7.0, 18.0, 14.0), Color(0.55, 0.28, 0.08))
		draw_rect(Rect2(-9.0, -9.0, 18.0, 5.0), Color(0.82, 0.58, 0.18))
		draw_rect(Rect2(-1.0, -5.0, 2.0, 7.0), Color(1.0, 0.9, 0.35))
		return
	if kind == &"burger":
		draw_rect(Rect2(-10.0, -5.0, 20.0, 10.0), Color(0.48, 0.22, 0.08))
		draw_rect(Rect2(-10.0, -8.0, 20.0, 6.0), Color(0.95, 0.65, 0.2))
		draw_rect(Rect2(-10.0, 1.0, 20.0, 5.0), Color(0.35, 0.72, 0.2))
		return
	var color := EXPERIENCE_COLOR if kind == &"xp" else GOLD_COLOR
	draw_circle(Vector2.ZERO, RADIUS, color)
