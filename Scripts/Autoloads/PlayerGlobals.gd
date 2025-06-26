extends Node

# UI Signals for real-time updates
signal hp_changed(current_hp: float, max_hp: float)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal ammo_changed(current_ready: int, current_reserves: int)
signal reload_started(reload_time: float)
signal reload_finished()

# Stamina
var max_stamina:= 100.0
var current_stamina:= 100.0
var stamina_regen_per_sec:= 12.5
var roll_cost:= 25.0

# Ammo system
var max_hp:= 100
var current_hp:= 100
var max_ammo_ready:= 8
var current_ammo_ready:= 8
var max_ammo_reserves:= 32
var current_ammo_reserves:= 32
var reload_speed:= 1.0  # Reload time in seconds (upgradeable)

# Helper functions to emit signals when values change
func set_hp(new_hp: float):
	current_hp = clamp(new_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)

func set_stamina(new_stamina: float):
	current_stamina = clamp(new_stamina, 0, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)

func set_ammo_ready(new_ammo: int):
	current_ammo_ready = clamp(new_ammo, 0, max_ammo_ready)
	ammo_changed.emit(current_ammo_ready, current_ammo_reserves)

func set_ammo_reserves(new_reserves: int):
	current_ammo_reserves = clamp(new_reserves, 0, max_ammo_reserves)
	ammo_changed.emit(current_ammo_ready, current_ammo_reserves)

func start_reload():
	reload_started.emit(reload_speed)

func finish_reload():
	reload_finished.emit()
