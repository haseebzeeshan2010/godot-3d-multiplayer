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
var jump_count = 0
var camera_instance
var state = PlayerState.IDLE # Set to default state

enum PlayerState {
	IDLE,
	WALKING,
	JUMP_STARTED,
	JUMPING,
	DOUBLE_JUMPING,
	FALLING
}

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
	# Only the authority should run physics
	# if not is_multiplayer_authority():
	# 	return

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
func handle_movement_state():
	# Decide State Of Player
	if Input.is_action_just_pressed("jump") and is_on_floor():
		state = PlayerState.JUMP_STARTED
	elif is_on_floor() and is_zero_approx(velocity.x):
		state = PlayerState.IDLE
	elif is_on_floor() and not is_zero_approx(velocity.x):
		state = PlayerState.WALKING
	else:
		state = PlayerState.JUMPING
	
	if velocity.y > 0.0 and not is_on_floor():
		if Input.is_action_just_pressed("jump"):
			state = PlayerState.DOUBLE_JUMPING
		else:
			state = PlayerState.FALLING
	
	# Process States For Player
	match state:
		PlayerState.IDLE:
			player_sprite.play("idle")
			jump_count = 0
		PlayerState.WALKING:
			player_sprite.play("walk")
			jump_count = 0
		PlayerState.JUMP_STARTED:
			player_sprite.play("jump_start")
			jump_count += 1
			velocity.y = -jump_strength
		PlayerState.JUMPING:
			pass
		PlayerState.DOUBLE_JUMPING:
			player_sprite.play("double_jump_start")
			jump_count += 1
			if jump_count <= max_jumps:
				velocity.y = -jump_strength
		PlayerState.FALLING:
			player_sprite.play("fall")
		
	# Jump Cancelling
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y = 0.0
