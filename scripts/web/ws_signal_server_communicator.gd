extends SignalServerCommunicator
class_name WebSocketSignalServerCommunicator

var server_url: String
var room_code: String 

var socket: WebSocketPeer

signal socket_opened

func _init(_server_url: String, _room_code: String) -> void:
	server_url = _server_url
	room_code  = _room_code
	socket = WebSocketPeer.new()

func _ready() -> void:
	# Instantiate the WebSocket client

	# Attempt connection to server_url/room_code
	var url : String = "%s/%s" % [server_url, room_code]
	var err : int = socket.connect_to_url(url)
	if err != OK:
		push_error("Unable to connect to %s: %s" % [url, err])
		set_process(false)
	else:
		set_process(true)
		await get_tree().create_timer(1).timeout

func _process(delta: float) -> void:
	# Poll drives internal state and triggers incoming data
	socket.poll()
	var state: int = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		# Handle all pending messages
		socket_opened.emit()
		while socket.get_available_packet_count() > 0:
			var pkt : PackedByteArray = socket.get_packet()
			var msg : String = pkt.get_string_from_utf8()
			message_received.emit(msg)

	elif state == WebSocketPeer.STATE_CLOSING:
		# Waiting for clean close; keep polling
		pass

	elif state == WebSocketPeer.STATE_CLOSED:
		# Connection fully closed
		var code : int = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)

func send(msg: String) -> void:
	# Send text only when the connection is open
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(msg)
	else:
		push_error("Cannot send: WebSocket is not open")
