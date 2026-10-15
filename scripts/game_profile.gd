extends Node

signal profile_changed

const DEFAULT_SAVE_PATH := "user://survivors_black_save.cfg"
const BASE_HEALTH := 100
const HEALTH_PER_UPGRADE := 20
const BASE_PICKUP_RADIUS := 48.0
const PICKUP_RADIUS_PER_UPGRADE := 32.0
const MAX_UPGRADE_LEVEL := 5
const DEFAULT_KEY_BINDINGS := {
	&"move_up": KEY_W,
	&"move_left": KEY_A,
	&"move_down": KEY_S,
	&"move_right": KEY_D,
	&"ability": KEY_F,
	&"pause_game": KEY_ESCAPE,
}

var profile_path := DEFAULT_SAVE_PATH
var banked_gold := 0
var health_upgrade_level := 0
var pickup_radius_upgrade_level := 0
var sfx_volume := 100.0
var music_volume := 100.0
var key_bindings: Dictionary = DEFAULT_KEY_BINDINGS.duplicate()
var _run_reward_committed := true


func _ready() -> void:
	_ensure_audio_bus("SFX")
	_ensure_audio_bus("Music")
	_load_profile()
	_apply_key_bindings()
	_apply_audio_settings()


func begin_run() -> void:
	_run_reward_committed = false


func finish_run(run_gold: int) -> void:
	if _run_reward_committed:
		return
	_run_reward_committed = true
	banked_gold += maxi(0, run_gold)
	_save_profile()
	profile_changed.emit()


func get_max_health() -> int:
	return BASE_HEALTH + health_upgrade_level * HEALTH_PER_UPGRADE


func get_pickup_radius() -> float:
	return BASE_PICKUP_RADIUS + pickup_radius_upgrade_level * PICKUP_RADIUS_PER_UPGRADE


func get_upgrade_level(kind: StringName) -> int:
	match kind:
		&"health":
			return health_upgrade_level
		&"pickup_radius":
			return pickup_radius_upgrade_level
	return 0


func get_upgrade_cost(kind: StringName) -> int:
	var level := get_upgrade_level(kind)
	if level < 0 or level >= MAX_UPGRADE_LEVEL:
		return -1
	return (level + 1) * 10


func purchase_upgrade(kind: StringName) -> bool:
	if kind != &"health" and kind != &"pickup_radius":
		return false
	var cost := get_upgrade_cost(kind)
	if cost < 0 or banked_gold < cost:
		return false
	banked_gold -= cost
	match kind:
		&"health":
			health_upgrade_level += 1
		&"pickup_radius":
			pickup_radius_upgrade_level += 1
		_:
			return false
	_save_profile()
	profile_changed.emit()
	return true


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 100.0)
	_apply_bus_volume("SFX", sfx_volume)
	_save_profile()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	_apply_bus_volume("Music", music_volume)
	_save_profile()


func get_key_binding(action: StringName) -> int:
	return int(key_bindings.get(action, DEFAULT_KEY_BINDINGS.get(action, 0)))


func set_key_binding(action: StringName, keycode: int) -> bool:
	if not DEFAULT_KEY_BINDINGS.has(action) or keycode <= 0:
		return false
	for other_action in key_bindings:
		if other_action != action and int(key_bindings[other_action]) == keycode:
			return false
	key_bindings[action] = keycode
	_apply_action_binding(action)
	_save_profile()
	profile_changed.emit()
	return true


func _load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(profile_path) != OK:
		return
	banked_gold = maxi(0, int(config.get_value("wallet", "gold", 0)))
	health_upgrade_level = clampi(int(config.get_value("upgrades", "health", 0)), 0, MAX_UPGRADE_LEVEL)
	pickup_radius_upgrade_level = clampi(int(config.get_value("upgrades", "pickup_radius", 0)), 0, MAX_UPGRADE_LEVEL)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", 100.0)), 0.0, 100.0)
	music_volume = clampf(float(config.get_value("audio", "music", 100.0)), 0.0, 100.0)
	var loaded_bindings: Dictionary = DEFAULT_KEY_BINDINGS.duplicate()
	for action in DEFAULT_KEY_BINDINGS:
		loaded_bindings[action] = int(config.get_value("controls", String(action), DEFAULT_KEY_BINDINGS[action]))
	var used_keycodes: Dictionary = {}
	for action in loaded_bindings:
		var keycode := int(loaded_bindings[action])
		if keycode <= 0 or used_keycodes.has(keycode):
			loaded_bindings = DEFAULT_KEY_BINDINGS.duplicate()
			break
		used_keycodes[keycode] = true
	key_bindings = loaded_bindings


func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("wallet", "gold", banked_gold)
	config.set_value("upgrades", "health", health_upgrade_level)
	config.set_value("upgrades", "pickup_radius", pickup_radius_upgrade_level)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "music", music_volume)
	for action in key_bindings:
		config.set_value("controls", String(action), int(key_bindings[action]))
	var error := config.save(profile_path)
	if error != OK:
		push_error("Could not save profile: %s" % error_string(error))


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _apply_audio_settings() -> void:
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("Music", music_volume)


func _apply_key_bindings() -> void:
	for action in key_bindings:
		_apply_action_binding(action)


func _apply_action_binding(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.physical_keycode = int(key_bindings[action])
	InputMap.action_add_event(action, event)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var normalized := value / 100.0
	AudioServer.set_bus_volume_db(bus_index, -80.0 if normalized <= 0.0 else linear_to_db(normalized))
