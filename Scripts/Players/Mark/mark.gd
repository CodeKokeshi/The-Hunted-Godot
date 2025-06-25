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
const SPEED = 300.0
const ROLL_SPEED = 500.0
const ATTACK_LUNGE_SPEED = 200.0
var movement_locked = false
var lunge_direction = Vector2.ZERO

# Animation and rotation
@onready var animation_player = $animation
var target_rotation = 0.0
var rotation_tween: Tween

# Input tracking
var input_direction = Vector2.ZERO
var is_aiming = false

func _ready():
	# Initialize the state machine
	change_state(PlayerState.IDLE)
	
	# Connect animation finished signal
	animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	handle_input()
	update_state(delta)
	move_and_slide()

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
			if Input.is_action_just_pressed("roll") and input_direction != Vector2.ZERO:
				change_state(PlayerState.ROLLING)
			elif Input.is_action_just_pressed("attack") and is_aiming:
				change_state(PlayerState.FIRING)
			elif Input.is_action_just_pressed("attack"):
				change_state(PlayerState.ATTACKING)
			elif is_aiming:
				change_state(PlayerState.AIMING)
			elif input_direction != Vector2.ZERO:
				change_state(PlayerState.RUNNING)
		
		PlayerState.RUNNING:
			if Input.is_action_just_pressed("roll"):
				change_state(PlayerState.ROLLING)
			elif Input.is_action_just_pressed("attack") and is_aiming:
				change_state(PlayerState.FIRING)
			elif Input.is_action_just_pressed("attack"):
				change_state(PlayerState.ATTACKING)
			elif is_aiming:
				change_state(PlayerState.AIMING)
			elif input_direction == Vector2.ZERO:
				change_state(PlayerState.IDLE)
		
		PlayerState.AIMING:
			if Input.is_action_just_pressed("attack"):
				change_state(PlayerState.FIRING)
			elif not is_aiming:
				if input_direction != Vector2.ZERO:
					change_state(PlayerState.RUNNING)
				else:
					change_state(PlayerState.IDLE)
		
		# Other states (FIRING, ATTACKING, ROLLING) transition automatically via animation_finished

# ============================================================================
# ROTATION AND MOVEMENT HELPERS
# ============================================================================

func rotate_to_direction(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	
	var angle = 0.0
	if direction.x > 0:  # Right
		angle = 0.0
	elif direction.x < 0:  # Left
		angle = PI
	elif direction.y < 0:  # Up
		angle = -PI/2
	elif direction.y > 0:  # Down
		angle = PI/2
	
	smooth_rotate_to(angle)

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
	var mouse_pos = get_global_mouse_position()
	look_at(mouse_pos)

func _on_animation_finished():
	# Handle animation finished events
	match current_state:
		PlayerState.FIRING:
			if is_aiming:
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

func exit_aiming():
	movement_locked = false

func during_aiming(_delta: float):
	velocity = Vector2.ZERO
	look_at_mouse()

# ============================================================================
# FIRING STATE
# ============================================================================

func enter_firing():
	animation_player.play("firing")
	movement_locked = true
	velocity = Vector2.ZERO

func exit_firing():
	pass

func during_firing(_delta: float):
	velocity = Vector2.ZERO

# ============================================================================
# ATTACKING STATE
# ============================================================================

func enter_attacking():
	animation_player.play("knife")
	movement_locked = true
	# Store current facing direction for lunge
	lunge_direction = Vector2(cos(rotation), sin(rotation))

func exit_attacking():
	movement_locked = false
	lunge_direction = Vector2.ZERO

func during_attacking(_delta: float):
	# Lunge forward slightly in the facing direction
	velocity = lunge_direction * ATTACK_LUNGE_SPEED

# ============================================================================
# ROLLING STATE
# ============================================================================

func enter_rolling():
	animation_player.play("roll")
	movement_locked = true
	# Store current facing direction for roll
	lunge_direction = Vector2(cos(rotation), sin(rotation))

func exit_rolling():
	movement_locked = false
	lunge_direction = Vector2.ZERO

func during_rolling(_delta: float):
	# Dash forward in the facing direction
	velocity = lunge_direction * ROLL_SPEED
