extends Node2D

const DURATION := 0.25
const MAX_RADIUS := 180.0

var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= DURATION:
		queue_free()


func _draw() -> void:
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	var color := Color(0.45, 0.85, 1.0, 1.0 - progress)
	draw_arc(Vector2.ZERO, MAX_RADIUS * progress, 0.0, TAU, 48, color, 4.0)
