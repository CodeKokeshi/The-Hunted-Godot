extends CharacterBody2D

# For Player Hitbox just for now if it collides with anything just use tween to simulate bullet destruction, because the collision mask is already set to enemy hurtbox. and the layer is already set to player hitbox, remember no need for group checking.
# For Wall Detection just for now if it collides with anything just use tween to simulate bullet destruction, as for this, the collision mask is also set to detect walls. so don't bother checking for groups
# The reason the two is separated is the hurtbox of enemy is area2d
# While the wall is a body but either way just for now, bother with animations, no damage system or anything like that yet aight.

func _ready() -> void:
	# Propel forward (default is facing right and upon spawn (the player rotates right?) so I think we've no problem if we just pass the player rotation to this)
	# Make the speed around 700
	pass

func _on_hitbox_area_entered(area: Area2D) -> void:
	# For player hitbox.
	pass


func _on_hitbox_body_entered(body: Node2D) -> void:
	# For wall detection.
	pass
