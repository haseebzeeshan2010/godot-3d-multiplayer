extends CharacterBody2D
#@export exposes values to godot's inspector


@export var player_camera: PackedScene
@export var camera_height = -132

@export var player_sprite: AnimatedSprite2D
@export var movement_speed: float = 300.0
@export var gravity = 30.0
@export var jump_strength = 600.0
@export var max_jumps = 1

@onready var initial_sprite_scale = player_sprite.scale

var owner_id = 1
var jump_counter = 0
var camera_instance

func _enter_tree():
	print(name.to_int())
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)
	if owner_id != multiplayer.get_unique_id():
		return
	
	
	set_up_camera()

# Camera Follow without Smoothing
# func _process(delta: float) -> void:
# 	camera_instance.global_position.x = global_position.x

func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	# Only process input and movement for the local player
	if multiplayer.multiplayer_peer == null:
		return
	if owner_id != multiplayer.get_unique_id():
		return

	#Smooth Camera Follow
	update_camera_pos(global_position.x, _delta)
	
	#Move the Player
	var horizontal_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = horizontal_input * movement_speed
	velocity.y += gravity
	
	#Handle Movement States
	handle_movement_state()

	
	#Moves the player(built-in function)
	move_and_slide()

	#Face Movement Direction
	face_movement_direction(horizontal_input)

	

	

# Animation Finished Signal Handle
func _on_animated_sprite_2d_animation_finished() -> void:
	player_sprite.play("jump")

#Set up Camera
func set_up_camera():
	camera_instance = player_camera.instantiate()
	camera_instance.global_position.y = camera_height
	get_tree().current_scene.add_child.call_deferred(camera_instance)

#Smooth Camera Follow
func update_camera_pos(new_x_position: float, _delta: float) -> void:
	camera_instance.global_position.x = lerp(camera_instance.global_position.x, new_x_position, _delta * 5.0)

#Flip the Player
func face_movement_direction(horizontal_input: float) -> void:
	if not is_zero_approx(horizontal_input):
		if horizontal_input < 0:
			player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
		elif horizontal_input > 0:
			player_sprite.scale = initial_sprite_scale


#Handle Movement States
func handle_movement_state() -> void:
	var is_grounded = is_on_floor()
	var wants_to_jump = Input.is_action_just_pressed("jump")
	var is_moving = not is_zero_approx(velocity.x)
	
	# Handle jumping logic first (before animations)
	if wants_to_jump:
		if is_grounded:
			# Regular jump from ground
			jump_counter = 1
			velocity.y = -jump_strength
			player_sprite.play("jump_start")
			return
		elif jump_counter < max_jumps:
			# Air jump (double jump, triple jump, etc.)
			jump_counter += 1
			velocity.y = -jump_strength
			player_sprite.play("double_jump_start")
			return
	
	# Reset jump counter when landing
	if is_grounded:
		jump_counter = 0
	
	# Handle jump release for variable jump height (optional)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5  # Cut jump short for tap jumps
	
	# Play animations based on current state
	if is_grounded:
		if is_moving:
			player_sprite.play("walk")
		else:
			player_sprite.play("idle")
	else:
		# Airborne
		if velocity.y < 0:
			# Only play jump if not already in a jump animation
			if not player_sprite.animation.begins_with("jump") and not player_sprite.animation.begins_with("double"):
				player_sprite.play("jump")
		else:
			player_sprite.play("fall")
