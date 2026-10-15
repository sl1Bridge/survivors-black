extends Node

signal xp_changed(current_xp: int, required_xp: int, current_level: int)
signal upgrade_choices_started(current_level: int)
signal upgrade_choices_finished

var inventory: Node
var current_xp := 0
var current_level := 1
var awaiting_upgrade_choice := false


func configure(inventory_node: Node) -> void:
	inventory = inventory_node


func add_xp(amount: int) -> void:
	if amount <= 0 or awaiting_upgrade_choice:
		return
	current_xp += amount
	if current_xp >= get_required_xp():
		_begin_level_up()
	else:
		_emit_xp_changed()


func get_required_xp() -> int:
	return current_level * 5


func get_current_xp() -> int:
	return current_xp


func get_current_level() -> int:
	return current_level


func choose_pistol_upgrade() -> void:
	if not awaiting_upgrade_choice:
		return
	inventory.call("upgrade_pistol")
	awaiting_upgrade_choice = false
	if current_xp >= get_required_xp():
		_begin_level_up()
		return
	upgrade_choices_finished.emit()
	get_tree().paused = false


func _begin_level_up() -> void:
	current_xp -= get_required_xp()
	current_level += 1
	awaiting_upgrade_choice = true
	get_tree().paused = true
	_emit_xp_changed()
	upgrade_choices_started.emit(current_level)


func _emit_xp_changed() -> void:
	xp_changed.emit(current_xp, get_required_xp(), current_level)
