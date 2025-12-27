extends Node

@export var ui: Control
@export var level_container: Node
@export var level_scene: PackedScene
@export var ip_line_edit: LineEdit
@export var status_label: Label
@export var not_connected_hbox: HBoxContainer
@export var host_hbox: HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	Lobby.player_connected.connect(_on_lobby_player_connected)
	# Auto-host for dedicated server builds
	if OS.has_feature("dedicated_server"):
		_on_host_button_pressed()

func _on_lobby_player_connected(_peer_id, _player_info):
	# Auto-start when 2 players connected for server builds
	if OS.has_feature("dedicated_server") and Lobby.players.size() >= Lobby.MAX_CONNECTIONS:
		_on_start_button_pressed()
		print("Starting game as %s players have connected." % (Lobby.players.size() - 1))

func _on_host_button_pressed():
	not_connected_hbox.hide()
	host_hbox.show()
	status_label.text = "Hosting!"
	Lobby.create_game()
	

func _on_join_button_pressed():
	not_connected_hbox.hide()
	Lobby.join_game(ip_line_edit.text)
	status_label.text = "Connecting..."

func _on_start_button_pressed():
	hide_menu.rpc()
	change_level.call_deferred(level_scene) # Use call_deferred to avoid changing scene during signal emission

func change_level(scene):
	for c in level_container.get_children():
		level_container.remove_child(c)
		c.queue_free()
	level_container.add_child(scene.instantiate())

func _on_connection_failed():
	status_label.text = "Failed to connect"
	not_connected_hbox.show()

func _on_connected_to_server():
	status_label.text = "Connected!"

@rpc("call_local", "authority", "reliable")
func hide_menu():
	ui.hide()
