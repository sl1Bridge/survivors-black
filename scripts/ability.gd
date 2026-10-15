extends Node2D

signal cooldown_changed(seconds_remaining: float)

const WAVE_SCENE: PackedScene = preload("res://scenes/ability_wave.tscn")
const COOLDOWN := 30.0
const WAVE_RADIUS := 180.0
const KNOCKBACK_DISTANCE := 100.0
const KNOCKBACK_DURATION := 0.25

var player: Node2D
var cooldown_remaining := 0.0
var _last_displayed_second := 0


func configure(player_node: Node2D) -> void:
	player = player_node


func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		var old_second := ceili(cooldown_remaining)
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
		var new_second := ceili(cooldown_remaining)
		if new_second != old_second:
			cooldown_changed.emit(cooldown_remaining)
	if Input.is_action_just_pressed("ability"):
		activate()


func activate() -> bool:
	if cooldown_remaining > 0.0 or not is_instance_valid(player) or player.get("is_dead"):
		return false
	cooldown_remaining = COOLDOWN
	_last_displayed_second = ceili(cooldown_remaining)
	cooldown_changed.emit(cooldown_remaining)
	var wave: Node2D = WAVE_SCENE.instantiate() as Node2D
	wave.global_position = player.global_position
	get_parent().add_child(wave)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var enemy_node := enemy as Node2D
		var offset := enemy_node.global_position - player.global_position
		if offset.length() > WAVE_RADIUS:
			continue
		if offset.is_zero_approx():
			offset = Vector2.RIGHT
		enemy_node.call("apply_knockback", offset.normalized(), KNOCKBACK_DISTANCE, KNOCKBACK_DURATION)
	return true


func get_cooldown_remaining() -> float:
	return cooldown_remaining
