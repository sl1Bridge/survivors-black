extends Node2D

const SPEED := 400.0
const RADIUS := 12.0
const DAMAGE := 10
const TRAIL_LENGTH := 42.0

var target_player: Node2D
var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var direction := Vector2.RIGHT
var distance_travelled := 0.0
var player_was_hit := false
var hit_enemies: Dictionary = {}
var is_finished := false


func configure(player_node: Node2D, start: Vector2, finish: Vector2) -> void:
	target_player = player_node
	start_position = start
	end_position = finish
	direction = (finish - start).normalized()
	global_position = start


func _process(delta: float) -> void:
	if is_finished:
		return
	var total_distance := start_position.distance_to(end_position)
	var step := minf(SPEED * delta, total_distance - distance_travelled)
	var previous_position := global_position
	var next_position := previous_position + direction * step
	_check_player_hit(previous_position, next_position)
	_check_enemy_hits(previous_position, next_position)
	global_position = next_position
	distance_travelled += step
	if distance_travelled >= total_distance:
		is_finished = true
		queue_free()


func _check_player_hit(segment_start: Vector2, segment_end: Vector2) -> void:
	if player_was_hit or not is_instance_valid(target_player) or target_player.get("is_dead"):
		return
	var touch_distance := RADIUS + float(target_player.call("get_collision_radius"))
	if _distance_to_segment(target_player.global_position, segment_start, segment_end) <= touch_distance:
		player_was_hit = true
		target_player.call("take_contact_damage", DAMAGE)


func _check_enemy_hits(segment_start: Vector2, segment_end: Vector2) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		var enemy := candidate as Node2D
		var instance_id := enemy.get_instance_id()
		if hit_enemies.has(instance_id):
			continue
		var touch_distance := RADIUS + float(enemy.call("get_collision_radius"))
		if _distance_to_segment(enemy.global_position, segment_start, segment_end) <= touch_distance:
			hit_enemies[instance_id] = true
			enemy.call("take_damage", DAMAGE)


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	if segment.is_zero_approx():
		return point.distance_to(segment_start)
	var projection := clampf((point - segment_start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(segment_start + segment * projection)


func _draw() -> void:
	draw_line(-direction * TRAIL_LENGTH, Vector2.ZERO, Color(0.3, 0.72, 1.0, 0.8), 5.0, true)
	draw_circle(Vector2.ZERO, RADIUS, Color(0.72, 0.92, 1.0))
	draw_circle(Vector2.ZERO, RADIUS * 0.5, Color.WHITE)
