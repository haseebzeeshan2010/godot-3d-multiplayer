extends Node2D

@export var door_open: Sprite2D
@export var door_closed: Sprite2D
@export var is_open = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	is_open = true
	area.get_owner().queue_free()
	set_door_properties()

func set_door_properties():
	door_open.visible = is_open
	door_closed.visible = !is_open
