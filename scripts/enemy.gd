extends Node2D

signal defeated(world_position: Vector2, is_elite: bool)

const MOVE_SPEED := 200.0
const COLLISION_RADIUS := 14.0
const CONTACT_DAMAGE := 10
const PLACEHOLDER_COLOR := Color(1.0, 0.28, 0.25)
const ELITE_HEALTH := 60
const ELITE_ATTACK_RANGE := 300.0
const ELITE_ATTACK_INTERVAL := 2.0
const ELITE_PROJECTILE_SPEED := 260.0
const ELITE_PROJECTILE_DAMAGE := 15
const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemy_projectile.tscn")

var target_player: Node2D
var projectile_container: Node2D
var is_elite := false
var max_health := 30
var current_health := 30
var is_defeated := false
var elite_attack_cooldown := 0.0
var knockback_velocity := Vector2.ZERO
var knockback_remaining := 0.0


func setup(player: Node2D, elite: bool = false, projectiles: Node2D = null) -> void:
	target_player = player
	is_elite = elite
	projectile_container = projectiles
	max_health = ELITE_HEALTH if is_elite else 30
	current_health = max_health


func _process(delta: float) -> void:
	if is_defeated or not is_instance_valid(target_player) or target_player.get("is_dead"):
		return

	elite_attack_cooldown = maxf(0.0, elite_attack_cooldown - delta)
	if knockback_remaining > 0.0:
		var knockback_step := minf(delta, knockback_remaining)
		global_position += knockback_velocity * knockback_step
		knockback_remaining -= knockback_step
		_keep_inside_viewport()
	else:
		var to_player := target_player.global_position - global_position
		var distance_to_player := to_player.length()
		if not to_player.is_zero_approx() and (not is_elite or distance_to_player > ELITE_ATTACK_RANGE):
			global_position += to_player / distance_to_player * MOVE_SPEED * delta
		if is_elite and distance_to_player <= ELITE_ATTACK_RANGE and elite_attack_cooldown <= 0.0:
			_shoot_at_player()
			elite_attack_cooldown = ELITE_ATTACK_INTERVAL

	var touching_distance := COLLISION_RADIUS + float(target_player.call("get_collision_radius"))
	if global_position.distance_to(target_player.global_position) <= touching_distance:
		target_player.call("take_contact_damage", CONTACT_DAMAGE)


func take_damage(amount: int) -> void:
	if is_defeated:
		return
	current_health = maxi(0, current_health - amount)
	if current_health == 0:
		is_defeated = true
		defeated.emit(global_position, is_elite)
		queue_free()


func apply_knockback(direction: Vector2, distance: float, duration: float) -> void:
	if is_defeated or duration <= 0.0 or direction.is_zero_approx():
		return
	knockback_velocity = direction.normalized() * distance / duration
	knockback_remaining = maxf(knockback_remaining, duration)


func get_collision_radius() -> float:
	return COLLISION_RADIUS


func _shoot_at_player() -> void:
	if not is_instance_valid(projectile_container):
		return
	var direction := target_player.global_position - global_position
	if direction.is_zero_approx():
		return
	var projectile: Node2D = ENEMY_PROJECTILE_SCENE.instantiate() as Node2D
	projectile.call("configure", target_player, direction.normalized(), ELITE_PROJECTILE_DAMAGE, ELITE_PROJECTILE_SPEED)
	projectile.global_position = global_position
	projectile_container.add_child(projectile)


func _keep_inside_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, COLLISION_RADIUS, viewport_size.x - COLLISION_RADIUS)
	global_position.y = clampf(global_position.y, COLLISION_RADIUS, viewport_size.y - COLLISION_RADIUS)


func _draw() -> void:
	draw_circle(Vector2.ZERO, COLLISION_RADIUS, Color(1.0, 0.78, 0.2) if is_elite else PLACEHOLDER_COLOR)
	if is_elite:
		var star := PackedVector2Array()
		for point in range(10):
			var angle := -PI * 0.5 + point * PI / 5.0
			var radius := 10.0 if point % 2 == 0 else 4.0
			star.append(Vector2(0.0, -25.0) + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(star, Color(1.0, 0.85, 0.2))
