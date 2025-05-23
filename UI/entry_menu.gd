extends Node

@onready var connection_menu := $"CanvasLayer/ConnectionMenu"
@onready var ip_entry := $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/IpEntry"
@onready var port_entry := $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/PortEntry"
@onready var room_code_entry := $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/RoomCodeEntry"
@onready var join_button := $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/JoinButton"
var map_manager := MapManager.new("TestMap")
var webRTCCon : WebRTCConStarter
var ip_addr := 'localhost'
var room_code := 'test_room'
var port := 1145
var ls := LogStream.new("entry_menu")
var game_main : GameMain

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_join_button_pressed() -> void:
	#ip_addr = ip_entry.text
	#room_code = room_code_entry.text
	var url : String = "ws://%s:%d/ws" % [ip_addr, port]
	ls.info("connecting to websocket: " + url)
	ls.info("room_code: " + room_code)
	var signaling : SignalServerCommunicator = WebSocketSignalServerCommunicator.new(url, room_code)
	webRTCCon = await WebRTCConStarter.new(signaling, room_code)
	add_child(webRTCCon)
	await webRTCCon.multi_peer_connecting
	multiplayer.multiplayer_peer = webRTCCon.multi_peer
	ls.info("multiplayer_peer set")
	connection_menu.hide()
	game_main = GameMain.new(webRTCCon.multi_peer, map_manager)
	add_child(game_main)

func _on_ip_entry_text_submitted(new_text: String) -> void:
	ip_addr = new_text


func _on_ip_entry_text_changed(new_text: String) -> void:
	ip_addr = new_text

func _on_port_entry_text_submitted(new_text: String) -> void:
	port = int(new_text)

func _on_port_entry_text_changed(new_text: String) -> void:
	port = int(new_text)

func _on_room_code_entry_text_changed(new_text: String) -> void:
	room_code = new_text

func _on_room_code_entry_text_submitted(new_text: String) -> void:
	room_code = new_text
