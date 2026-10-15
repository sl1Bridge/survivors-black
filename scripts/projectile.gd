extends Node2D

const RADIUS := 4.0
const HIT_PADDING := 2.0
const COLOR := Color(1.0, 0.88, 0.25)

var target: Node2D
var damage := 0
var speed := 180.0


func configure(target_node: Node2D, damage_amount: int, projectile_speed: float) -> void:
	target = target_node
	damage = damage_amount
	speed = projectile_speed


func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var target_radius := float(target.call("get_collision_radius"))
	if distance <= speed * delta + target_radius + HIT_PADDING:
		target.call("take_damage", damage)
		queue_free()
		return
	if distance > 0.0:
		global_position += to_target / distance * speed * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
