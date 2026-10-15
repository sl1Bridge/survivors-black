extends Node2D

signal destroyed(world_position: Vector2, loot_kind: StringName)

const MAX_HEALTH := 30
const COLLISION_RADIUS := 14.0

var current_health := MAX_HEALTH
var is_destroyed := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("event_objects")
	add_to_group("breakable_crates")
	rng.randomize()


func take_damage(amount: int) -> void:
	if is_destroyed or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	queue_redraw()
	if current_health > 0:
		return
	is_destroyed = true
	var loot_kind: StringName = &"gold" if rng.randi_range(0, 1) == 0 else &"xp"
	destroyed.emit(global_position, loot_kind)
	queue_free()


func get_collision_radius() -> float:
	return COLLISION_RADIUS


func _draw() -> void:
	draw_rect(Rect2(-12.0, -11.0, 24.0, 22.0), Color(0.45, 0.24, 0.11))
	draw_rect(Rect2(-12.0, -11.0, 24.0, 5.0), Color(0.72, 0.43, 0.2))
	draw_line(Vector2(-9.0, -7.0), Vector2(9.0, 7.0), Color(0.85, 0.66, 0.38), 2.0)
	draw_line(Vector2(9.0, -7.0), Vector2(-9.0, 7.0), Color(0.85, 0.66, 0.38), 2.0)
	var health_ratio := float(current_health) / float(MAX_HEALTH)
	draw_rect(Rect2(-12.0, -17.0, 24.0, 3.0), Color(0.18, 0.12, 0.1))
	draw_rect(Rect2(-12.0, -17.0, 24.0 * health_ratio, 3.0), Color(0.9, 0.35, 0.2))
