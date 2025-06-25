extends CharacterBody2D

# For Player Hitbox just for now if it collides with anything just use tween to simulate bullet destruction, because the collision mask is already set to enemy hurtbox. and the layer is already set to player hitbox, remember no need for group checking.
# For Wall Detection just for now if it collides with anything just use tween to simulate bullet destruction, as for this, the collision mask is also set to detect walls. so don't bother checking for groups
# The reason the two is separated is the hurtbox of enemy is area2d
# While the wall is a body but either way just for now, bother with animations, no damage system or anything like that yet aight.

const BULLET_SPEED = 1800.0
var direction = Vector2.RIGHT
var is_destroyed = false

func _ready() -> void:
	# Propel forward (default is facing right and upon spawn (the player rotates right?) so I think we've no problem if we just pass the player rotation to this)
	# Make the speed around 1200 (increased from 700)
	pass

func _physics_process(delta):
	if not is_destroyed:
		velocity = direction * BULLET_SPEED
		move_and_slide()

func set_direction_and_rotation(new_direction: Vector2, player_rotation: float):
	direction = new_direction.normalized()
	# Rotate the entire bullet (including hitbox) to match direction
	rotation = player_rotation

func destroy():
	if is_destroyed:
		return
	
	is_destroyed = true
	# Use tween to simulate bullet destruction
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)

func _on_hitbox_area_entered(area: Area2D) -> void:
	# For player hitbox.
	destroy()

func _on_hitbox_body_entered(body: Node2D) -> void:
	# For wall detection.
	destroy()
