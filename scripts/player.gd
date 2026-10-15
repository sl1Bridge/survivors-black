extends Node2D

const MOVE_SPEED := 240.0
const PLACEHOLDER_RADIUS := 16.0
const PLACEHOLDER_COLOR := Color.WHITE


func _ready() -> void:
	position = get_viewport_rect().size * 0.5


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * MOVE_SPEED * delta
	_keep_inside_viewport()


func _keep_inside_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	position.x = clampf(position.x, PLACEHOLDER_RADIUS, viewport_size.x - PLACEHOLDER_RADIUS)
	position.y = clampf(position.y, PLACEHOLDER_RADIUS, viewport_size.y - PLACEHOLDER_RADIUS)


func _draw() -> void:
	draw_circle(Vector2.ZERO, PLACEHOLDER_RADIUS, PLACEHOLDER_COLOR)
