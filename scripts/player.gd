extends Node2D

signal health_changed(current_health: int, max_health: int)
signal died

const MOVE_SPEED := 240.0
const PLACEHOLDER_RADIUS := 16.0
const PLACEHOLDER_COLOR := Color.WHITE
const BASE_HEALTH := 100
const BASE_PICKUP_RADIUS := 48.0
const CONTACT_DAMAGE_COOLDOWN := 1.0

var max_health := BASE_HEALTH
var current_health := BASE_HEALTH
var pickup_radius := BASE_PICKUP_RADIUS
var damage_cooldown := 0.0
var is_dead := false


func _ready() -> void:
	position = get_viewport_rect().size * 0.5
	health_changed.emit(current_health, max_health)


func configure_run(run_max_health: int, run_pickup_radius: float) -> void:
	max_health = maxi(BASE_HEALTH, run_max_health)
	current_health = max_health
	pickup_radius = maxf(BASE_PICKUP_RADIUS, run_pickup_radius)


func _process(delta: float) -> void:
	damage_cooldown = maxf(0.0, damage_cooldown - delta)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * MOVE_SPEED * delta
	_keep_inside_viewport()


func take_contact_damage(amount: int) -> void:
	if is_dead or damage_cooldown > 0.0:
		return
	damage_cooldown = CONTACT_DAMAGE_COOLDOWN
	take_damage(amount)


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		is_dead = true
		died.emit()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	var previous_health := current_health
	current_health = mini(max_health, current_health + amount)
	if current_health != previous_health:
		health_changed.emit(current_health, max_health)


func get_collision_radius() -> float:
	return PLACEHOLDER_RADIUS


func get_current_health() -> int:
	return current_health


func get_max_health() -> int:
	return max_health


func get_pickup_radius() -> float:
	return pickup_radius


func _keep_inside_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	position.x = clampf(position.x, PLACEHOLDER_RADIUS, viewport_size.x - PLACEHOLDER_RADIUS)
	position.y = clampf(position.y, PLACEHOLDER_RADIUS, viewport_size.y - PLACEHOLDER_RADIUS)


func _draw() -> void:
	draw_circle(Vector2.ZERO, PLACEHOLDER_RADIUS, PLACEHOLDER_COLOR)
