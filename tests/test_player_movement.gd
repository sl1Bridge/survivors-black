extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const MOVE_SPEED := 240.0
const PLACEHOLDER_RADIUS := 16.0
const TOLERANCE := 0.01

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(InputMap.has_action("move_up"), "Move-up action should exist")
	_check(InputMap.has_action("move_left"), "Move-left action should exist")
	_check(InputMap.has_action("move_down"), "Move-down action should exist")
	_check(InputMap.has_action("move_right"), "Move-right action should exist")

	root.size = Vector2i(1280, 900)
	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	root.add_child(player)
	await process_frame

	var viewport_center: Vector2 = player.get_viewport_rect().size * 0.5
	_check(player.position.is_equal_approx(viewport_center), "Player should start at the viewport center")

	var start: Vector2 = player.position
	Input.action_press("move_right")
	player._physics_process(1.0)
	Input.action_release("move_right")
	_check(
		absf(player.position.x - start.x - MOVE_SPEED) < TOLERANCE,
		"Horizontal movement should use the approved speed"
	)
	_check(absf(player.position.y - start.y) < TOLERANCE, "Horizontal input should not move vertically")

	start = player.position
	Input.action_press("move_right")
	Input.action_press("move_down")
	player._physics_process(1.0)
	Input.action_release("move_right")
	Input.action_release("move_down")
	var diagonal_delta: Vector2 = player.position - start
	_check(absf(diagonal_delta.length() - MOVE_SPEED) < TOLERANCE, "Diagonal movement should be normalized")
	_check(absf(diagonal_delta.x - diagonal_delta.y) < TOLERANCE, "Diagonal movement should affect both axes equally")

	player.position = Vector2(PLACEHOLDER_RADIUS, PLACEHOLDER_RADIUS)
	Input.action_press("move_left")
	Input.action_press("move_up")
	player._physics_process(1.0)
	Input.action_release("move_left")
	Input.action_release("move_up")
	_check(
		player.position.is_equal_approx(Vector2(PLACEHOLDER_RADIUS, PLACEHOLDER_RADIUS)),
		"Player should remain inside the viewport at its upper-left edge"
	)

	var viewport_bottom_right := player.get_viewport_rect().size - Vector2(PLACEHOLDER_RADIUS, PLACEHOLDER_RADIUS)
	player.position = viewport_bottom_right
	Input.action_press("move_right")
	Input.action_press("move_down")
	player._physics_process(1.0)
	Input.action_release("move_right")
	Input.action_release("move_down")
	_check(
		player.position.is_equal_approx(viewport_bottom_right),
		"Player should remain inside the viewport at its lower-right edge"
	)

	player.queue_free()
	await process_frame
	if failures > 0:
		push_error("%d player movement test(s) failed" % failures)
		quit(1)
	else:
		print("Player movement tests passed.")
		quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
