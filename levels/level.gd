extends Node2D

@export var players_container: Node2D
@export var player_scene: PackedScene
@export var spawn_points: Array[Node2D]

var next_spawn_point_index: int = 0

func _ready():
	if not multiplayer.is_server(): # Only the host/server manages players
		return

	# multiplayer.peer_connected.connect(add_player) # Subscribe to signal to add players when they join(for late joiners, though disabled as this game doesn't have any)

	multiplayer.peer_disconnected.connect(delete_player) # Subscribe to signal to remove players when they leave

	for id in multiplayer.get_peers(): # Add a player for each connected peer
		add_player(id)

	add_player(1) # Add a player for the host itself




func _exit_tree():
	# Only process input and movement for the local player
	if multiplayer.multiplayer_peer == null:
		return

	# Only the host/server manages players
	if not multiplayer.is_server(): 
		return

	# multiplayer.peer_connected.disconnect(add_player) # Unsubscribe from signal
	multiplayer.peer_disconnected.disconnect(delete_player) # Unsubscribe from signal

func add_player(id):
	var player_instance = player_scene.instantiate()
	player_instance.position = get_spawn_point()
	player_instance.name = str(id) # Set the name of the player node to the peer ID for easy access
	players_container.add_child(player_instance)

func delete_player(id):
	if not players_container.has_node(str(id)): # Check if player exists, return if not
		return

	players_container.get_node(str(id)).queue_free() # Remove player node

func get_spawn_point():
	var spawn_point = spawn_points[next_spawn_point_index].position
	next_spawn_point_index += 1
	if next_spawn_point_index >= len(spawn_points):
		next_spawn_point_index = 0
	return spawn_point
