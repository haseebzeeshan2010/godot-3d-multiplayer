extends Node

# Declare custom signals
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

# Setup constants
const PORT = 7000
const MAX_CONNECTIONS = 2

# Setup variables
var players = {}
var player_info = {"name" : "Missing Name"} #Default for name key is "Name"

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_game():
	# Create a new ENet multiplayer peer for the server
	var peer = ENetMultiplayerPeer.new()

	# Start the server
	var error = peer.create_server(PORT, MAX_CONNECTIONS)

	if error: # Check for errors
		return error
	
	multiplayer.multiplayer_peer = peer # Assign the peer to the multiplayer system

	players[1] = player_info # Add host player to players dictionary. Host player is always peer ID 1
	player_connected.emit(1, player_info)


func join_game(ip_address: String):
	# Create a new ENet multiplayer peer for the client
	var peer = ENetMultiplayerPeer.new()

	# Start the client and connect to the server
	var error = peer.create_client(ip_address, PORT)

	if error: # Check for errors
		return error
	
	multiplayer.multiplayer_peer = peer # Assign the peer to the multiplayer system

func _on_player_connected(id: int) -> void:
	_register_player.rpc_id(id, player_info) # Request the new player to register themselves

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id: int) -> void:
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info # Add this client to players dictionary
	player_connected.emit(peer_id, player_info)

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null # Clear the multiplayer peer on failure

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null # Clear the multiplayer peer on disconnection
	players.clear() # Clear the players dictionary
	server_disconnected.emit()
