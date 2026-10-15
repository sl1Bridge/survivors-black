extends Node2D

const RADIUS := 7.0
const COLOR := Color(1.0, 0.35, 0.2)

var target_player: Node2D
var direction := Vector2.ZERO
var damage := 15
var speed := 260.0


func configure(player: Node2D, shot_direction: Vector2, damage_amount: int, projectile_speed: float) -> void:
	target_player = player
	direction = shot_direction.normalized()
	damage = damage_amount
	speed = projectile_speed


func _process(delta: float) -> void:
	if not is_instance_valid(target_player) or target_player.get("is_dead"):
		queue_free()
		return
	global_position += direction * speed * delta
	var hit_distance := float(target_player.call("get_collision_radius")) + RADIUS
	if global_position.distance_to(target_player.global_position) <= hit_distance:
		target_player.call("take_damage", damage)
		queue_free()
		return
	var viewport_size := get_viewport_rect().size
	if global_position.x < -RADIUS or global_position.y < -RADIUS or global_position.x > viewport_size.x + RADIUS or global_position.y > viewport_size.y + RADIUS:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
