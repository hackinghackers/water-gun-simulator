extends SignalServerCommunicator
class_name WebSocketSignalServerCommunicator

@export var server_url: String = "ws://localhost:1145"
@export var room_code: String = "room_code"

var socket: WebSocketPeer

func _ready() -> void:
    # Instantiate the WebSocket client
    socket = WebSocketPeer.new()

    # Attempt connection to server_url/room_code
    var url : String = "%s/%s" % [server_url, room_code]
    var err : int = socket.connect_to_url(url)
    if err != OK:
        push_error("Unable to connect to %s: %s" % [url, err])
        set_process(false)
    else:
        set_process(true)

func _process(delta: float) -> void:
    # Poll drives internal state and triggers incoming data
    socket.poll()
    var state: int = socket.get_ready_state()

    if state == WebSocketPeer.STATE_OPEN:
        # Handle all pending messages
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
