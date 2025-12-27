extends Node2D

@export var is_locked: bool = true
@export var chest_locked: Sprite2D
@export var chest_unlocked: Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_interactable_interacted():
	if is_locked:
		is_locked = false
		set_chest_properties()

func set_chest_properties():
	chest_locked.visible = is_locked
	chest_unlocked.visible = !is_locked

func _on_multiplayer_synchronizer_delta_synchronized() -> void:
	set_chest_properties()
