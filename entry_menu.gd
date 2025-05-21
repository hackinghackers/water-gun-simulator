extends Node

@onready var connection_menu = $"CanvasLayer/ConnectionMenu"
@onready var ip_entry = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/IpEntry"
@onready var port_entry = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/PortEntry"
@onready var join_button = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/JoinButton"
@onready var host_button = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/HostButton"
var default_map = preload("res://addons/Map/TemplateMapScene.tscn").instantiate()
const PlayerType := preload("res://addons/PlayerCharacter/PlayerCharacterScene.tscn") 
var webRTCCon : WebRTCConStarter
var ip_addr : String
var room_code : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_join_button_pressed() -> void:
	ip_addr = ip_entry.text
	room_code = port_entry.text

	var signaling : SignalServerCommunicator = WebSocketSignalServerCommunicator.new(ip_addr, room_code)
	webRTCCon = WebRTCConStarter.new(signaling, room_code)
	multiplayer.multiplayer_peer = webRTCCon.multi_peer
	add_child(webRTCCon)

func _on_ip_entry_text_submitted(new_text: String) -> void:
	ip_addr = new_text


func _on_port_entry_text_submitted(new_text: String) -> void:
	room_code = new_text

func _on_ip_entry_text_changed(new_text: String) -> void:
	ip_addr = new_text


func _on_port_entry_text_changed(new_text: String) -> void:
	room_code = new_text
