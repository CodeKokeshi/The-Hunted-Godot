# Example of how to add PlayerUI to your main game scene
# Add this script to your main scene or level scene

extends Node2D

@onready var player_ui = preload("res://Scenes/UI/PlayerUI.tscn")

func _ready():
	# Add the UI to the scene
	var ui_instance = player_ui.instantiate()
	add_child(ui_instance)
	
	# Optional: If you want to manually update UI without signals, you can call:
	# ui_instance.manual_update_ammo(PlayerGlobals.current_ammo_ready, PlayerGlobals.current_ammo_reserves)
	# ui_instance.manual_update_stamina(PlayerGlobals.current_stamina, PlayerGlobals.max_stamina)
	
	print("PlayerUI added to scene with automatic signal connections!")
