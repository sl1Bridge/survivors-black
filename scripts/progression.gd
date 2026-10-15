extends Node

signal xp_changed(current_xp: int, required_xp: int, current_level: int)
signal upgrade_choices_started(current_level: int, source: StringName)
signal upgrade_choices_finished

var inventory: Node
var current_xp := 0
var current_level := 1
var awaiting_upgrade_choice := false
var pending_choices: Array[StringName] = []


func configure(inventory_node: Node) -> void:
	inventory = inventory_node


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	current_xp += amount
	while current_xp >= get_required_xp():
		current_xp -= get_required_xp()
		current_level += 1
		pending_choices.append(&"level")
	_emit_xp_changed()
	_show_next_choice()


func request_chest_choice() -> void:
	pending_choices.append(&"chest")
	_show_next_choice()


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
	if pending_choices.is_empty():
		_finish_choices()
	else:
		_show_next_choice()


func _show_next_choice() -> void:
	if awaiting_upgrade_choice or pending_choices.is_empty():
		return
	var source: StringName = pending_choices.pop_front()
	awaiting_upgrade_choice = true
	get_tree().paused = true
	upgrade_choices_started.emit(current_level, source)


func _finish_choices() -> void:
	awaiting_upgrade_choice = false
	upgrade_choices_finished.emit()
	get_tree().paused = false


func _emit_xp_changed() -> void:
	xp_changed.emit(current_xp, get_required_xp(), current_level)
