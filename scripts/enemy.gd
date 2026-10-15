extends Node2D

signal defeated(world_position: Vector2)

const MOVE_SPEED := 200.0
const MAX_HEALTH := 30
const COLLISION_RADIUS := 14.0
const CONTACT_DAMAGE := 10
const PLACEHOLDER_COLOR := Color(1.0, 0.28, 0.25)

var target_player: Node2D
var current_health := MAX_HEALTH
var is_defeated := false


func setup(player: Node2D) -> void:
	target_player = player


func _process(delta: float) -> void:
	if is_defeated or not is_instance_valid(target_player) or target_player.get("is_dead"):
		return

	var to_player := target_player.global_position - global_position
	if not to_player.is_zero_approx():
		global_position += to_player.normalized() * MOVE_SPEED * delta

	var touching_distance := COLLISION_RADIUS + float(target_player.call("get_collision_radius"))
	if global_position.distance_to(target_player.global_position) <= touching_distance:
		target_player.call("take_contact_damage", CONTACT_DAMAGE)


func take_damage(amount: int) -> void:
	if is_defeated:
		return
	current_health = maxi(0, current_health - amount)
	if current_health == 0:
		is_defeated = true
		defeated.emit(global_position)
		queue_free()


func get_collision_radius() -> float:
	return COLLISION_RADIUS


func _draw() -> void:
	draw_circle(Vector2.ZERO, COLLISION_RADIUS, PLACEHOLDER_COLOR)
