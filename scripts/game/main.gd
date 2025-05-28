class_name GameMain extends Node
const PlayerScene := preload("res://PlayerCharacter/PlayerCharacterScene.tscn")
var ls := LogStream.new("game_main")
var multiplayer_peer : MultiplayerPeer
var map_manager : MapManager
var player_dict : Dictionary[int, PlayerCharacter] = {}

func _init(_multiplayer_peer : MultiplayerPeer, _map_manager : MapManager) -> void:
	multiplayer_peer = _multiplayer_peer
	map_manager = _map_manager
	

func _ready() -> void:
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.allow_object_decoding = true
	ls.info("multiplayer_peer set")
	add_child(map_manager)
	add_player(multiplayer.get_unique_id()) # add the local player


func add_player(player_id : int) -> void: 
	print_stack()
	var player := PlayerScene.instantiate()
	player.name = str(player_id)
	player.set_multiplayer_authority(player_id)
	player_dict[player_id] = player
	var spawn_pt := map_manager.get_rand_spawn_pt()
	player.position = spawn_pt
	ls.info("Adding player with ID: %d at " % player_id, spawn_pt)
	add_child(player)
	ls.info("This instance's authority on the new player[id=%d] is " % player_id, player.is_multiplayer_authority())	

	# reconnect transition signal 
	var authority_player : PlayerCharacter = player_dict.get(multiplayer.get_unique_id())
	authority_player.get_node("StateMachine").reconnectTransition()
	authority_player.get_node("StateMachine").test_rpc.rpc()

func remove_player(player_id : int) -> void:
	ls.info("Removing player with ID: %d" % player_id)
	var player := get_node_or_null(str(player_id))
	if player:
		player.queue_free()
