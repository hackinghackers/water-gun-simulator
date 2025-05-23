class_name GameMain extends Node
const PlayerType := preload("res://PlayerCharacter/PlayerCharacterScene.tscn")
var ls := LogStream.new("game_main")
var multiplayer_peer : MultiplayerPeer
var map_manager : MapManager


func _init(_multiplayer_peer : MultiplayerPeer, _map_manager : MapManager) -> void:
	multiplayer_peer = _multiplayer_peer
	map_manager = _map_manager
	add_child(map_manager)
	

func _ready() -> void:
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.multiplayer_peer = multiplayer_peer
	ls.info("multiplayer_peer set")
	add_child(map_manager.map_inst)


func add_player(player_id : int) -> void: 
	var player := PlayerType.instantiate()
	player.name = str(player_id)
	var spawn_pt := map_manager.get_rand_spawn_pt()
	player.position = spawn_pt
	add_child(player)
	pass

func remove_player(player_id : int) -> void:
	var player := get_node_or_null(str(player_id))
	if player:
		player.queue_free()
