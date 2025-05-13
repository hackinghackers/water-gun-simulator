class_name WebRTCConStarter extends Node

var conn: WebRTCPeerConnection

func _ready() -> void:
	conn = WebRTCPeerConnection.new()
	conn.session_description_created.connect(_on_local_session)


func _on_local_session() -> void:
	pass
