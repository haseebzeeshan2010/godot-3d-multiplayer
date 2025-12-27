extends Node2D

@export var players_container: Node2D
@export var player_scene: PackedScene
@export var spawn_points: Array[Node2D]
@export var player_spawner: MultiplayerSpawner

var next_spawn_point_index: int = 0

func _ready():
	# Set custom spawn function
	player_spawner.spawn_function = spawn_player
	
	if not multiplayer.is_server():
		return

	multiplayer.peer_disconnected.connect(delete_player) # Subscribe to disconnection signal

	var peers = multiplayer.get_peers() # Get list of connected peers
	
	for id in peers:
		add_player(id) # Add existing players from peers list

	if not OS.has_feature("dedicated_server"):
		add_player(1) # Add a player for the host itself

# Cleanup on exit
func _exit_tree():
	if multiplayer.multiplayer_peer == null:
		return
	if not multiplayer.is_server(): # Only the server manages player disconnections
		return
	multiplayer.peer_disconnected.disconnect(delete_player) # Unsubscribe from disconnection signal

# Function to add a player with given ID
func add_player(id):
	var spawn_pos = get_spawn_point()
	# Pass both id and position as spawn data
	player_spawner.spawn({"id": id, "position": spawn_pos})

# This function is called by the player_spawner to instantiate a player with correct data
func spawn_player(data):
	# This runs on ALL peers (server and clients)
	var player_instance = player_scene.instantiate()
	player_instance.name = str(data["id"])
	player_instance.position = data["position"]
	return player_instance

# Function to delete a player with given ID
func delete_player(id):
	if not players_container.has_node(str(id)):
		return
	players_container.get_node(str(id)).queue_free()

# Function to get the next spawn point
func get_spawn_point():
	var spawn_point = spawn_points[next_spawn_point_index].position
	next_spawn_point_index += 1
	if next_spawn_point_index >= len(spawn_points):
		next_spawn_point_index = 0
	return spawn_point


func _on_test_interact(state: Variant) -> void:
	pass # Replace with function body.
