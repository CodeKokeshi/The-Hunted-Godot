extends Control

# UI Elements
@onready var hp_bar: ProgressBar = $DarkPanel/VBoxContainer/BarsContainer/HPContainer/HPBar
@onready var hp_label: Label = $DarkPanel/VBoxContainer/BarsContainer/HPContainer/HPLabel
@onready var stamina_bar: ProgressBar = $DarkPanel/VBoxContainer/BarsContainer/StaminaContainer/StaminaBar
@onready var stamina_label: Label = $DarkPanel/VBoxContainer/BarsContainer/StaminaContainer/StaminaLabel
@onready var ammo_label: Label = $DarkPanel/VBoxContainer/AmmoContainer/AmmoLabel
@onready var reload_indicator: Label = $StatusPanel/ReloadIndicator

# Animation tweens
var hp_tween: Tween
var stamina_tween: Tween
var reload_tween: Tween

# Color constants
const HP_COLOR = Color.RED
const STAMINA_COLOR = Color.GREEN
const FLASH_COLOR = Color.WHITE

# Previous values for color change detection
var previous_hp: float = 100.0
var previous_stamina: float = 100.0

# Update throttling to prevent lag
var stamina_update_timer: float = 0.0
const STAMINA_UPDATE_INTERVAL: float = 0.05  # Update every 50ms instead of every frame

# UI Animation settings
const TWEEN_DURATION = 0.3
const RELOAD_FLASH_DURATION = 0.1

func _ready():
	# Connect to PlayerGlobals signals for updates
	if PlayerGlobals.has_signal("hp_changed"):
		PlayerGlobals.hp_changed.connect(_on_hp_changed)
	if PlayerGlobals.has_signal("stamina_changed"):
		PlayerGlobals.stamina_changed.connect(_on_stamina_changed)
	if PlayerGlobals.has_signal("ammo_changed"):
		PlayerGlobals.ammo_changed.connect(_on_ammo_changed)
	if PlayerGlobals.has_signal("reload_started"):
		PlayerGlobals.reload_started.connect(_on_reload_started)
	if PlayerGlobals.has_signal("reload_finished"):
		PlayerGlobals.reload_finished.connect(_on_reload_finished)
	
	# Set initial bar colors (removed since we're using StyleBox theming)
	# Labels remain white for visibility
	if hp_label:
		hp_label.modulate = Color.WHITE
	if stamina_label:
		stamina_label.modulate = Color.WHITE
	
	# Initialize UI values
	update_hp_display()
	update_stamina_display()
	update_ammo_display()
	hide_reload_indicator()

func _process(delta):
	# Throttle stamina updates to prevent lag
	stamina_update_timer += delta
	if stamina_update_timer >= STAMINA_UPDATE_INTERVAL:
		update_stamina_efficiently()
		stamina_update_timer = 0.0

func update_stamina_efficiently():
	# Update stamina only when needed (not every frame)
	if stamina_bar:
		var current_stamina = PlayerGlobals.current_stamina
		var max_stamina = PlayerGlobals.max_stamina
		stamina_bar.value = (current_stamina / max_stamina) * 100.0
		
		# Check for changes and handle color flashing
		if abs(current_stamina - previous_stamina) > 0.1:  # Only flash on significant changes
			if current_stamina < previous_stamina:
				flash_stamina_bar(false)  # Stamina used
			elif current_stamina > previous_stamina and previous_stamina < max_stamina:
				# Only flash on regen if we're actually regenerating (not at max)
				flash_stamina_bar(true)   # Stamina gained
			previous_stamina = current_stamina

# ============================================================================
# HP SYSTEM
# ============================================================================

func update_hp_display():
	if not hp_bar:
		return
	
	# Use placeholder values since HP system isn't implemented yet
	var current_hp = 100.0 if not PlayerGlobals.has_method("get_current_hp") else PlayerGlobals.get_current_hp()
	var max_hp = 100.0 if not PlayerGlobals.has_method("get_max_hp") else PlayerGlobals.get_max_hp()
	
	# Animate bar
	animate_progress_bar(hp_bar, current_hp / max_hp)

func _on_hp_changed(current_hp: float, _max_hp: float):
	# Check if HP increased or decreased for color flash
	if current_hp != previous_hp:
		if current_hp < previous_hp:
			flash_hp_bar(false)  # Damage taken
		else:
			flash_hp_bar(true)   # HP gained
		previous_hp = current_hp
	
	update_hp_display()

func flash_hp_bar(is_increase: bool = false):
	if hp_tween:
		hp_tween.kill()
	
	# Flash the entire progress bar container for visibility
	var flash_color = Color.WHITE if not is_increase else Color.CYAN
	var original_color = Color.WHITE
	
	hp_tween = create_tween()
	hp_tween.tween_property(hp_bar, "modulate", flash_color, RELOAD_FLASH_DURATION)
	hp_tween.tween_property(hp_bar, "modulate", original_color, RELOAD_FLASH_DURATION)

# ============================================================================
# STAMINA SYSTEM
# ============================================================================

func update_stamina_display():
	if not stamina_bar:
		return
	
	var current_stamina = PlayerGlobals.current_stamina
	var max_stamina = PlayerGlobals.max_stamina
	
	# Update bar value
	stamina_bar.value = (current_stamina / max_stamina) * 100.0
	previous_stamina = current_stamina

func _on_stamina_changed(_current_stamina: float, _max_stamina: float):
	# This will be called if you add stamina change signals later
	update_stamina_display()

func flash_stamina_bar(is_increase: bool = false):
	if stamina_tween:
		stamina_tween.kill()
	
	# Flash the entire progress bar container for visibility
	var flash_color = Color.WHITE if not is_increase else Color.YELLOW
	var original_color = Color.WHITE
	
	stamina_tween = create_tween()
	stamina_tween.tween_property(stamina_bar, "modulate", flash_color, RELOAD_FLASH_DURATION)
	stamina_tween.tween_property(stamina_bar, "modulate", original_color, RELOAD_FLASH_DURATION)

# ============================================================================
# AMMO SYSTEM
# ============================================================================

func update_ammo_display():
	if not ammo_label:
		return
	
	var current_ammo = PlayerGlobals.current_ammo_ready
	var max_ammo = PlayerGlobals.max_ammo_ready
	var reserves = PlayerGlobals.current_ammo_reserves
	
	# Update ammo display: "Ammo: 8/32" (magazine/reserves)
	ammo_label.text = "Ammo: %d/%d" % [current_ammo, reserves]
	
	# Color coding for ammo levels
	if current_ammo == 0:
		ammo_label.modulate = Color.RED
	elif current_ammo < max_ammo * 0.3:
		ammo_label.modulate = Color.YELLOW
	else:
		ammo_label.modulate = Color.WHITE

func _on_ammo_changed(_current_ready: int, _current_reserves: int):
	update_ammo_display()
	
	# Flash effect when ammo is consumed
	flash_ammo_label()

func flash_ammo_label():
	if hp_tween:
		hp_tween.kill()
	
	hp_tween = create_tween()
	hp_tween.tween_property(ammo_label, "scale", Vector2(1.2, 1.2), 0.05)
	hp_tween.tween_property(ammo_label, "scale", Vector2(1.0, 1.0), 0.05)

# ============================================================================
# RELOAD SYSTEM
# ============================================================================

func _on_reload_started(reload_time: float):
	show_reload_indicator(reload_time)

func _on_reload_finished():
	hide_reload_indicator()
	update_ammo_display()

func show_reload_indicator(_reload_time: float):
	if not reload_indicator:
		return
	
	reload_indicator.text = "RELOADING..."
	reload_indicator.visible = true
	
	# Animate reload indicator
	if reload_tween:
		reload_tween.kill()
	
	reload_tween = create_tween()
	reload_tween.set_loops()
	reload_tween.tween_property(reload_indicator, "modulate:a", 0.3, 0.5)
	reload_tween.tween_property(reload_indicator, "modulate:a", 1.0, 0.5)

func hide_reload_indicator():
	if not reload_indicator:
		return
	
	if reload_tween:
		reload_tween.kill()
	
	reload_indicator.visible = false
	reload_indicator.modulate.a = 1.0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func animate_progress_bar(bar: ProgressBar, target_value: float):
	if not bar:
		return
	
	target_value = clamp(target_value * 100.0, 0.0, 100.0)
	
	if hp_tween:
		hp_tween.kill()
	
	hp_tween = create_tween()
	hp_tween.set_ease(Tween.EASE_OUT)
	hp_tween.set_trans(Tween.TRANS_CUBIC)
	hp_tween.tween_property(bar, "value", target_value, TWEEN_DURATION)

# Manual update functions (call these from player script if signals aren't available)
func manual_update_hp(current_hp: float, max_hp: float):
	_on_hp_changed(current_hp, max_hp)

func manual_update_stamina(current_stamina: float, max_stamina: float):
	_on_stamina_changed(current_stamina, max_stamina)

func manual_update_ammo(current_ready: int, current_reserves: int):
	_on_ammo_changed(current_ready, current_reserves)

func manual_reload_started(reload_time: float):
	_on_reload_started(reload_time)

func manual_reload_finished():
	_on_reload_finished()
