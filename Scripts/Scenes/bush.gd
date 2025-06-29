extends Area2D

var player_in_bush = false
var player_node: Node2D = null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_bush = true
		player_node = body
		print("Player entered bush")
		
		# Only hide player if stealth is available (not on cooldown)
		if PlayerGlobals.can_enter_stealth():
			make_player_transparent()
			PlayerGlobals.set_stealth_state(true)
		else:
			print("Cannot enter stealth - still on cooldown")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_bush = false
		print("Player exited bush")
		
		# Always make player visible when exiting bush
		make_player_visible()
		PlayerGlobals.set_stealth_state(false)
		player_node = null

func make_player_transparent():
	if player_node:
		# Make player 30% visible (70% transparent)
		player_node.modulate.a = 0.3
		print("Player made transparent")

func make_player_visible():
	if player_node:
		# Make player fully visible
		player_node.modulate.a = 1.0
		print("Player made visible")

func _ready():
	# Connect to stealth broken signal to handle when player loses stealth
	PlayerGlobals.stealth_broken.connect(_on_stealth_broken)
	# Connect to stealth cooldown finished to allow re-entering stealth if player is still in bush
	PlayerGlobals.stealth_cooldown_finished.connect(_on_stealth_cooldown_finished)

func _on_stealth_broken():
	# If player is in bush and stealth is broken, make them visible
	if player_in_bush and player_node:
		make_player_visible()
		print("Stealth broken while in bush - player now visible")

func _on_stealth_cooldown_finished():
	# If player is still in bush when cooldown finishes, allow them to enter stealth
	if player_in_bush and player_node and not PlayerGlobals.player_hidden:
		make_player_transparent()
		PlayerGlobals.set_stealth_state(true)
		print("Stealth cooldown finished - player can hide in bush again")
