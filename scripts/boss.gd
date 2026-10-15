extends Node2D

signal defeated

const MAX_HEALTH := 300
const MOVE_SPEED := 100.0
const COLLISION_RADIUS := 24.0
const CONTACT_DAMAGE := 10
const SUMMON_INTERVAL := 5.0
const SUMMON_COUNT := 2
const ENEMY_COLLISION_RADIUS := 14.0
const COLOR := Color(0.68, 0.25, 0.88)

var target_player: Node2D
var enemy_spawner: Node
var current_health := MAX_HEALTH
var summon_charge := 0.0
var is_defeated := false
var knockback_velocity := Vector2.ZERO
var knockback_remaining := 0.0
var summon_angle := 0.0


func _ready() -> void:
	add_to_group("enemies")


func configure(player_node: Node2D, spawner_node: Node) -> void:
	target_player = player_node
	enemy_spawner = spawner_node


func _process(delta: float) -> void:
	if is_defeated or not is_instance_valid(target_player) or target_player.get("is_dead"):
		return

	if knockback_remaining > 0.0:
		var knockback_step := minf(delta, knockback_remaining)
		global_position += knockback_velocity * knockback_step
		knockback_remaining -= knockback_step
		_keep_inside_viewport()
	else:
		var to_player := target_player.global_position - global_position
		var distance_to_player := to_player.length()
		if not to_player.is_zero_approx():
			global_position += to_player / distance_to_player * MOVE_SPEED * delta

	var touching_distance := COLLISION_RADIUS + float(target_player.call("get_collision_radius"))
	if global_position.distance_to(target_player.global_position) <= touching_distance:
		target_player.call("take_contact_damage", CONTACT_DAMAGE)

	summon_charge += delta
	while summon_charge >= SUMMON_INTERVAL:
		summon_charge -= SUMMON_INTERVAL
		_summon_regular_enemies()
	queue_redraw()


func take_damage(amount: int) -> void:
	if is_defeated or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	if current_health > 0:
		return
	is_defeated = true
	defeated.emit()
	queue_free()


func apply_knockback(direction: Vector2, distance: float, duration: float) -> void:
	if is_defeated or duration <= 0.0 or direction.is_zero_approx():
		return
	knockback_velocity = direction.normalized() * distance / duration
	knockback_remaining = maxf(knockback_remaining, duration)


func get_collision_radius() -> float:
	return COLLISION_RADIUS


func get_summon_progress() -> float:
	return summon_charge / SUMMON_INTERVAL


func _summon_regular_enemies() -> void:
	if not is_instance_valid(enemy_spawner):
		return
	summon_angle = fmod(summon_angle + 2.399963, TAU)
	var offset := Vector2.RIGHT.rotated(summon_angle) * (COLLISION_RADIUS + ENEMY_COLLISION_RADIUS + 4.0)
	var viewport_size := get_viewport_rect().size
	for index in range(SUMMON_COUNT):
		var spawn_position := global_position + offset.rotated(PI * index)
		spawn_position.x = clampf(spawn_position.x, ENEMY_COLLISION_RADIUS, viewport_size.x - ENEMY_COLLISION_RADIUS)
		spawn_position.y = clampf(spawn_position.y, ENEMY_COLLISION_RADIUS, viewport_size.y - ENEMY_COLLISION_RADIUS)
		enemy_spawner.call("spawn_enemy_at", spawn_position)


func _keep_inside_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, COLLISION_RADIUS, viewport_size.x - COLLISION_RADIUS)
	global_position.y = clampf(global_position.y, COLLISION_RADIUS, viewport_size.y - COLLISION_RADIUS)


func _draw() -> void:
	draw_circle(Vector2.ZERO, COLLISION_RADIUS, COLOR)
	draw_circle(Vector2.ZERO, COLLISION_RADIUS * 0.55, Color(0.92, 0.72, 1.0))
	var bar_rect := Rect2(Vector2(-36.0, -42.0), Vector2(72.0, 8.0))
	draw_rect(bar_rect, Color(0.12, 0.08, 0.16))
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * get_summon_progress(), bar_rect.size.y)), Color(0.4, 0.9, 1.0))
	draw_rect(bar_rect, Color(0.9, 0.85, 1.0), false, 1.0)
