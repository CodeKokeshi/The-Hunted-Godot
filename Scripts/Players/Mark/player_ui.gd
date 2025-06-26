extends CanvasLayer

# UI Elements
@onready var hp_bar: ProgressBar = $UIContainer/HPContainer/HPBar
@onready var hp_label: Label = $UIContainer/HPContainer/HPLabel
@onready var stamina_bar: ProgressBar = $UIContainer/StaminaContainer/StaminaBar
@onready var stamina_label: Label = $UIContainer/StaminaContainer/StaminaLabel
@onready var ammo_label: Label = $UIContainer/AmmoContainer/AmmoLabel

# Tween animations
var hp_tween: Tween
var stamina_tween: Tween
var ammo_tween: Tween

# Animation settings
const TWEEN_DURATION = 0.3
const SHAKE_INTENSITY = 5.0
const SHAKE_DURATION = 0.2

func _ready():
	# Connect to PlayerGlobals signals (we'll create these)
	setup_ui()
	update_all_ui()

func setup_ui():
	# Set up progress bars
	hp_bar.min_value = 0
	hp_bar.max_value = PlayerGlobals.max_hp
	hp_bar.value = PlayerGlobals.current_hp
	
	stamina_bar.min_value = 0
	stamina_bar.max_value = PlayerGlobals.max_stamina
	stamina_bar.value = PlayerGlobals.current_stamina
	
	# Update labels
	update_hp_label()
	update_stamina_label()
	update_ammo_label()

func update_all_ui():
	update_hp(PlayerGlobals.current_hp, PlayerGlobals.max_hp)
	update_stamina(PlayerGlobals.current_stamina, PlayerGlobals.max_stamina)
	update_ammo(PlayerGlobals.current_ammo_ready, PlayerGlobals.current_ammo_reserves)

# HP Updates
func update_hp(current: int, maximum: int):
	# Update bar max if it changed
	if hp_bar.max_value != maximum:
		hp_bar.max_value = maximum
	
	# Animate HP bar change
	if hp_tween:
		hp_tween.kill()
	
	hp_tween = create_tween()
	hp_tween.tween_property(hp_bar, "value", current, TWEEN_DURATION)
	
	# Shake effect if HP decreased
	if current < hp_bar.value:
		shake_element(hp_bar)
	
	# Update label
	update_hp_label()

func update_hp_label():
	hp_label.text = "HP: %d/%d" % [PlayerGlobals.current_hp, PlayerGlobals.max_hp]

# Stamina Updates
func update_stamina(current: float, maximum: float):
	# Update bar max if it changed
	if abs(stamina_bar.max_value - maximum) > 0.1:
		stamina_bar.max_value = maximum
	
	# Animate stamina bar change
	if stamina_tween:
		stamina_tween.kill()
	
	stamina_tween = create_tween()
	stamina_tween.tween_property(stamina_bar, "value", current, TWEEN_DURATION)
	
	# Shake effect if stamina was consumed significantly
	if current < stamina_bar.value - 20:  # If lost more than 20 stamina
		shake_element(stamina_bar)
	
	# Update label
	update_stamina_label()

func update_stamina_label():
	stamina_label.text = "Stamina: %d/%d" % [int(PlayerGlobals.current_stamina), int(PlayerGlobals.max_stamina)]

# Ammo Updates
func update_ammo(ammo_ready: int, ammo_reserves: int):
	# Update label with flash effect
	update_ammo_label()
	
	# Flash effect for ammo changes
	if ammo_tween:
		ammo_tween.kill()
	
	ammo_tween = create_tween()
	ammo_tween.parallel().tween_property(ammo_label, "modulate:a", 0.5, 0.1)
	ammo_tween.parallel().tween_property(ammo_label, "scale", Vector2(1.2, 1.2), 0.1)
	ammo_tween.tween_property(ammo_label, "modulate:a", 1.0, 0.1)
	ammo_tween.parallel().tween_property(ammo_label, "scale", Vector2(1.0, 1.0), 0.1)

func update_ammo_label():
	ammo_label.text = "Ammo: %d/%d" % [PlayerGlobals.current_ammo_ready, PlayerGlobals.current_ammo_reserves]
	
	# Change color based on ammo status
	if PlayerGlobals.current_ammo_ready == 0:
		ammo_label.modulate = Color.RED
	elif PlayerGlobals.current_ammo_ready <= 2:
		ammo_label.modulate = Color.YELLOW
	else:
		ammo_label.modulate = Color.WHITE

# Shake animation for elements
func shake_element(element: Control):
	var original_pos = element.position
	
	var shake_tween = create_tween()
	for i in range(5):
		var offset = Vector2(
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		)
		shake_tween.tween_property(element, "position", original_pos + offset, SHAKE_DURATION / 10)
	
	shake_tween.tween_property(element, "position", original_pos, SHAKE_DURATION / 10)

# Public methods to be called from outside
func on_hp_changed(current: int, maximum: int):
	update_hp(current, maximum)

func on_stamina_changed(current: float, maximum: float):
	update_stamina(current, maximum)

func on_ammo_changed(ready: int, reserves: int):
	update_ammo(ready, reserves)
