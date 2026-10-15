extends Node

signal changed

const SLOT_COUNT := 4

var slots: Array[String] = ["pistol", "", "", ""]
var pistol_level := 1
var pistol_damage := 10
var pistol_fire_rate := 1.0


func upgrade_pistol() -> void:
	pistol_level += 1
	pistol_damage += 5
	pistol_fire_rate *= 1.25
	changed.emit()


func get_slot_text(index: int) -> String:
	if index < 0 or index >= SLOT_COUNT or slots[index].is_empty():
		return "ПУСТО"
	if slots[index] == "pistol":
		return "ПИСТОЛЕТ\nур. %d" % pistol_level
	return "ПУСТО"


func get_pistol_damage() -> int:
	return pistol_damage


func get_pistol_fire_rate() -> float:
	return pistol_fire_rate
