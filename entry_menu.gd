extends Node

@onready var connection_menu = $"CanvasLayer/ConnectionMenu"
@onready var ip_entry = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/IpEntry"
@onready var port_entry = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/PortEntry"
@onready var join_button = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/JoinButton"
@onready var host_button = $"CanvasLayer/ConnectionMenu/MarginContainer/VBoxContainer/HostButton"
var default_map = preload("res://addons/Map/TemplateMapScene.tscn").instantiate()
const PlayerType = preload("res://addons/PlayerCharacter/PlayerCharacterScene.tscn") 

var webRTC_peer = WebRTCMultiplayerPeer.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_host_button_pressed() -> void:
	pass # Replace with function body.


func _on_join_button_pressed() -> void:
	pass # Replace with function body.



func _on_ip_entry_text_submitted(new_text: String) -> void:
	pass # Replace with function body.


func _on_port_entry_text_submitted(new_text: String) -> void:
	pass # Replace with function body.


func _on_ip_entry_text_changed(new_text: String) -> void:
	pass # Replace with function body.


func _on_port_entry_text_changed(new_text: String) -> void:
	pass # Replace with function body.
