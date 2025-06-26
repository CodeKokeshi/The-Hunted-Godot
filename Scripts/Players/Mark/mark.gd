extends CharacterBody2D

# Player state machine for animation and movement
enum PlayerState {
	IDLE,
	RUNNING,
	AIMING,
	FIRING,
	ATTACKING,
	ROLLING
}

# State machine variables
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# Movement variables
const SPEED = 400.0
const ROLL_SPEED = 560.0
const ATTACK_LUNGE_SPEED = 200.0
var movement_locked = false
var lunge_direction = Vector2.ZERO

# Animation and rotation
@onready var animation_player = $animation
@onready var bullet_spawn_point = $bullet_spawn
var target_rotation = 0.0
var rotation_tween: Tween

# Bullet system
const BULLET_SCENE = preload("res://Scenes/Players/bullet.tscn")

# Input tracking
var input_direction = Vector2.ZERO
var is_aiming = false

# Reload system
var reload_timer = 0.0
var is_reloading = false

# Firing rotation control - prevents awkward bullet direction when changing aim during firing
var can_rotate_while_firing = true

# Firing rate control - creates gap between shots for rotation updates
var fire_rate_timer = 0.0
var fire_rate_delay = 0.05  # 50ms gap between shots (adjustable)
var is_currently_firing = false  # Prevents multiple bullets per animation cycle

func _ready():
	# Initialize the state machine
	change_state(PlayerState.IDLE)
	
	# Initialize rotation control (allow rotation by default)
	can_rotate_while_firing = true
	
	# Connect animation finished signal
	animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	handle_input()
	update_state(delta)
	regenerate_stamina(delta)
	move_and_slide()

# ============================================================================
# STAMINA SYSTEM
# ============================================================================

func regenerate_stamina(delta: float):
	# Only regenerate if not at max stamina
	if PlayerGlobals.current_stamina < PlayerGlobals.max_stamina:
		PlayerGlobals.current_stamina += PlayerGlobals.stamina_regen_per_sec * delta
		# Clamp to max stamina
		PlayerGlobals.current_stamina = min(PlayerGlobals.current_stamina, PlayerGlobals.max_stamina)

func has_enough_stamina_for_roll() -> bool:
	return PlayerGlobals.current_stamina >= PlayerGlobals.roll_cost

func consume_roll_stamina():
	PlayerGlobals.current_stamina -= PlayerGlobals.roll_cost
	# Ensure it doesn't go below 0
	PlayerGlobals.current_stamina = max(PlayerGlobals.current_stamina, 0)

# ============================================================================
# STATE MACHINE FUNCTIONS
# ============================================================================

func change_state(new_state: PlayerState):
	if current_state == new_state:
		return
	
	# Exit current state
	exit_state(current_state)
	
	# Change state
	previous_state = current_state
	current_state = new_state
	
	# Enter new state
	enter_state(current_state)

# Enter state logic
func enter_state(state: PlayerState):
	match state:
		PlayerState.IDLE:
			enter_idle()
		PlayerState.RUNNING:
			enter_running()
		PlayerState.AIMING:
			enter_aiming()
		PlayerState.FIRING:
			enter_firing()
		PlayerState.ATTACKING:
			enter_attacking()
		PlayerState.ROLLING:
			enter_rolling()

# Exit state logic
func exit_state(state: PlayerState):
	match state:
		PlayerState.IDLE:
			exit_idle()
		PlayerState.RUNNING:
			exit_running()
		PlayerState.AIMING:
			exit_aiming()
		PlayerState.FIRING:
			exit_firing()
		PlayerState.ATTACKING:
			exit_attacking()
		PlayerState.ROLLING:
			exit_rolling()

# Update state logic (during)
func update_state(delta: float):
	# Handle reload timer separately from state machine
	handle_reload_timer(delta)
	
	# Handle fire rate timer
	handle_fire_rate_timer(delta)
	
	match current_state:
		PlayerState.IDLE:
			during_idle(delta)
		PlayerState.RUNNING:
			during_running(delta)
		PlayerState.AIMING:
			during_aiming(delta)
		PlayerState.FIRING:
			during_firing(delta)
		PlayerState.ATTACKING:
			during_attacking(delta)
		PlayerState.ROLLING:
			during_rolling(delta)

# ============================================================================
# INPUT HANDLING
# ============================================================================

func handle_input():
	# Get movement input
	input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("left", "right")
	input_direction.y = Input.get_axis("up", "down")
	input_direction = input_direction.normalized()
	
	# Track aiming input
	is_aiming = Input.is_action_pressed("aim")
	
	# Handle state transitions based on input
	handle_state_transitions()

func handle_state_transitions():
	match current_state:
		PlayerState.IDLE:
			if Input.is_action_just_pressed("reload"):
				start_reload()
			elif Input.is_action_just_pressed("roll") and input_direction != Vector2.ZERO and has_enough_stamina_for_roll():
				change_state(PlayerState.ROLLING)
			elif Input.is_action_pressed("attack") and is_aiming and not is_reloading:
				if PlayerGlobals.current_ammo_ready > 0:
					change_state(PlayerState.FIRING)
				elif PlayerGlobals.current_ammo_reserves > 0:
					# Auto-reload when trying to shoot with 0 ammo
					start_reload()
			elif Input.is_action_just_pressed("attack"):
				change_state(PlayerState.ATTACKING)
			elif is_aiming:
				change_state(PlayerState.AIMING)
			elif input_direction != Vector2.ZERO:
				change_state(PlayerState.RUNNING)
		
		PlayerState.RUNNING:
			if Input.is_action_just_pressed("reload"):
				start_reload()
			elif Input.is_action_just_pressed("roll") and has_enough_stamina_for_roll():
				change_state(PlayerState.ROLLING)
			elif Input.is_action_pressed("attack") and is_aiming and not is_reloading:
				if PlayerGlobals.current_ammo_ready > 0:
					change_state(PlayerState.FIRING)
				elif PlayerGlobals.current_ammo_reserves > 0:
					# Auto-reload when trying to shoot with 0 ammo
					start_reload()
			elif Input.is_action_just_pressed("attack"):
				change_state(PlayerState.ATTACKING)
			elif is_aiming:
				change_state(PlayerState.AIMING)
			elif input_direction == Vector2.ZERO:
				change_state(PlayerState.IDLE)
		
		PlayerState.AIMING:
			if Input.is_action_just_pressed("reload"):
				start_reload()
			elif Input.is_action_pressed("attack") and not is_reloading:
				if PlayerGlobals.current_ammo_ready > 0:
					change_state(PlayerState.FIRING)
				elif PlayerGlobals.current_ammo_reserves > 0:
					# Auto-reload when trying to shoot with 0 ammo
					start_reload()
			elif not is_aiming:
				if input_direction != Vector2.ZERO:
					change_state(PlayerState.RUNNING)
				else:
					change_state(PlayerState.IDLE)
		
		# Other states (FIRING, ATTACKING, ROLLING, RELOADING) transition automatically via animation_finished or timer

# ============================================================================
# ROTATION AND MOVEMENT HELPERS
# ============================================================================

func rotate_to_direction(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	
	# Calculate the target angle from the direction vector
	var target_angle = direction.angle()
	
	# Check if we're already facing approximately the same direction
	var angle_diff = abs(target_angle - rotation)
	if angle_diff > PI:
		angle_diff = 2 * PI - angle_diff
	
	# Only rotate if the difference is significant (more than ~5 degrees)
	if angle_diff > 0.1:
		smooth_rotate_to(target_angle)

func smooth_rotate_to(angle: float):
	if rotation_tween:
		rotation_tween.kill()
	
	# Calculate the angle difference
	var angle_diff = abs(angle - rotation)
	# Handle wrap-around for angles (e.g., from 350° to 10°)
	if angle_diff > PI:
		angle_diff = 2 * PI - angle_diff
	
	# Determine tween duration based on angle difference
	var tween_duration = 0.2  # Default smooth duration
	if angle_diff > PI/2:  # More than 90 degrees
		tween_duration = 0.05  # Snappy rotation
	
	rotation_tween = create_tween()
	rotation_tween.tween_property(self, "rotation", angle, tween_duration)

func look_at_mouse():
	if not can_rotate_while_firing and current_state == PlayerState.FIRING:
		# Debug: Uncomment the line below to see when rotation is blocked
		# print("Rotation blocked during firing to prevent awkward bullet directions")
		return # Don't rotate while firing to prevent awkward bullet directions
	
	var mouse_pos = get_global_mouse_position()
	look_at(mouse_pos)
	
@onready var gun_shake: PhantomCameraNoiseEmitter2D = $gun_shake

func spawn_bullet():
	gun_shake.emit()
	# Check if we have ammo
	if PlayerGlobals.current_ammo_ready <= 0:
		return
	
	# Consume ammo
	PlayerGlobals.current_ammo_ready -= 1
	
	# Create bullet instance
	var bullet = BULLET_SCENE.instantiate()
	
	# Set bullet position to spawn point
	bullet.global_position = bullet_spawn_point.global_position
	
	# Set bullet direction and rotation based on player rotation
	var bullet_direction = Vector2(cos(rotation), sin(rotation))
	bullet.set_direction_and_rotation(bullet_direction, rotation)
	
	# Add bullet to the scene tree (same level as player)
	get_parent().add_child(bullet)

func start_reload():
	# Check if we need to reload (not already full)
	if PlayerGlobals.current_ammo_ready >= PlayerGlobals.max_ammo_ready:
		return
	
	# Check if we have ammo in reserves
	if PlayerGlobals.current_ammo_reserves <= 0:
		return
	
	# Check if already reloading
	if is_reloading:
		return
	
	# Start reload timer
	is_reloading = true
	reload_timer = PlayerGlobals.reload_speed
	print("Starting reload... ", reload_timer, " seconds")

func reload_weapon():
	# Calculate how much ammo we need
	var ammo_needed = PlayerGlobals.max_ammo_ready - PlayerGlobals.current_ammo_ready
	
	# Calculate how much ammo we can actually reload
	var ammo_to_reload = min(ammo_needed, PlayerGlobals.current_ammo_reserves)
	
	# Transfer ammo from reserves to ready
	PlayerGlobals.current_ammo_reserves -= ammo_to_reload
	PlayerGlobals.current_ammo_ready += ammo_to_reload
	
	print("Reloaded: ", ammo_to_reload, " bullets. Ready: ", PlayerGlobals.current_ammo_ready, "/", PlayerGlobals.max_ammo_ready, " Reserves: ", PlayerGlobals.current_ammo_reserves, "/", PlayerGlobals.max_ammo_reserves)

func handle_reload_timer(delta: float):
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			# Reload finished
			reload_weapon()
			is_reloading = false
			reload_timer = 0.0

func handle_fire_rate_timer(delta: float):
	if fire_rate_timer > 0.0:
		fire_rate_timer -= delta
		if fire_rate_timer <= 0.0:
			fire_rate_timer = 0.0

func _on_animation_finished():
	# Handle animation finished events
	match current_state:
		PlayerState.FIRING:
			# Animation finished, allow next shot
			is_currently_firing = false
			# Set fire rate timer to create a gap between shots
			fire_rate_timer = fire_rate_delay
			# Re-enable rotation during the gap
			can_rotate_while_firing = true
			
			# Check if we should continue firing or transition to another state
			if is_aiming and Input.is_action_pressed("attack") and not is_reloading and PlayerGlobals.current_ammo_ready > 0:
				# Stay in firing state but don't immediately fire again
				# The actual firing will happen when fire_rate_timer reaches 0
				pass
			elif is_aiming:
				change_state(PlayerState.AIMING)
			else:
				if input_direction != Vector2.ZERO:
					change_state(PlayerState.RUNNING)
				else:
					change_state(PlayerState.IDLE)
		
		PlayerState.ATTACKING:
			if input_direction != Vector2.ZERO:
				change_state(PlayerState.RUNNING)
			else:
				change_state(PlayerState.IDLE)
		
		PlayerState.ROLLING:
			if input_direction != Vector2.ZERO:
				change_state(PlayerState.RUNNING)
			else:
				change_state(PlayerState.IDLE)

# ============================================================================
# IDLE STATE
# ============================================================================

func enter_idle():
	animation_player.play("idle")
	movement_locked = false
	velocity = Vector2.ZERO
	# Ensure rotation is enabled in idle state
	can_rotate_while_firing = true

func exit_idle():
	pass

func during_idle(_delta: float):
	velocity = Vector2.ZERO

# ============================================================================
# RUNNING STATE
# ============================================================================

func enter_running():
	animation_player.play("run")
	movement_locked = false
	# Ensure rotation is enabled in running state
	can_rotate_while_firing = true

func exit_running():
	pass

func during_running(_delta: float):
	if not movement_locked:
		rotate_to_direction(input_direction)
		velocity = input_direction * SPEED

# ============================================================================
# AIMING STATE
# ============================================================================

func enter_aiming():
	animation_player.play("aiming")
	movement_locked = true
	velocity = Vector2.ZERO
	# Ensure rotation is enabled when aiming (especially when transitioning from firing)
	can_rotate_while_firing = true

func exit_aiming():
	movement_locked = false

func during_aiming(_delta: float):
	velocity = Vector2.ZERO
	look_at_mouse()

# ============================================================================
# FIRING STATE
# ============================================================================

func enter_firing():
	# Update rotation to current mouse position before starting animation
	look_at_mouse()
	# Play firing animation
	animation_player.play("firing")
	movement_locked = true
	velocity = Vector2.ZERO
	# Lock rotation to prevent awkward bullet directions while firing animation plays
	can_rotate_while_firing = false
	# Set firing flag to prevent spam
	is_currently_firing = true
	# Spawn bullet when entering firing state
	spawn_bullet()

func exit_firing():
	# Re-enable rotation when exiting firing state
	can_rotate_while_firing = true
	# Reset firing flag
	is_currently_firing = false

func during_firing(_delta: float):
	velocity = Vector2.ZERO
	
	# Allow rotation updates during the fire rate gap
	if fire_rate_timer > 0.0:
		look_at_mouse()
	
	# Check if we can fire again (fire rate timer finished and not currently firing)
	if fire_rate_timer <= 0.0 and not is_currently_firing:
		# Check if we should continue firing
		if is_aiming and Input.is_action_pressed("attack") and not is_reloading and PlayerGlobals.current_ammo_ready > 0:
			# Update rotation one more time before firing
			look_at_mouse()
			# Lock rotation for the animation
			can_rotate_while_firing = false
			# Set firing flag to prevent spam
			is_currently_firing = true
			# Fire again
			animation_player.play("firing")
			spawn_bullet()
		elif not (is_aiming and Input.is_action_pressed("attack")):
			# Player stopped firing, transition to appropriate state
			if is_aiming:
				change_state(PlayerState.AIMING)
			elif input_direction != Vector2.ZERO:
				change_state(PlayerState.RUNNING)
			else:
				change_state(PlayerState.IDLE)

# ============================================================================
# ATTACKING STATE
# ============================================================================

func enter_attacking():
	animation_player.play("knife")
	movement_locked = true
	# Rotate to face current input direction first, then store it for lunge
	if input_direction != Vector2.ZERO:
		rotate_to_direction(input_direction)
		lunge_direction = input_direction
	else:
		# If no input, use current facing direction
		lunge_direction = Vector2(cos(rotation), sin(rotation))

func exit_attacking():
	movement_locked = false
	lunge_direction = Vector2.ZERO

func during_attacking(_delta: float):
	# Lunge forward in the stored direction
	velocity = lunge_direction * ATTACK_LUNGE_SPEED

# ============================================================================
# ROLLING STATE
# ============================================================================

func enter_rolling():
	animation_player.play("roll")
	movement_locked = true
	# Consume stamina for rolling
	consume_roll_stamina()
	# Rotate to face input direction first, then store it for roll
	rotate_to_direction(input_direction)
	lunge_direction = input_direction

func exit_rolling():
	movement_locked = false
	lunge_direction = Vector2.ZERO

func during_rolling(_delta: float):
	# Dash forward in the input direction
	velocity = lunge_direction * ROLL_SPEED
