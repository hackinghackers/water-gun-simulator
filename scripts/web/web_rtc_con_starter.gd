class_name WebRTCConStarter extends Node

const JsonCC = preload("res://addons/JsonClassConverter/JsonClassConverter.gd")

var room_code: String

var signaling: SignalServerCommunicator
var multi_peer: WebRTCMultiplayerPeer
var connections: Dictionary = {}
var own_peer_id: int = -1
var ls := LogStream.new("webrtc_con_starter")
signal multi_peer_connecting 

#
# Base for all signaling events.
# Now carries both a sender (from_pid) and a target (to_pid).
#
class SignalEvent:
	@export var generated_t: int # exporting for serializer to use
	@export var event_name: String
	@export var from_pid:   int  # who sent this message
	@export var to_pid:     int  # which peer should receive it
	@export var room_code:  String

	func _init(_event_name: String = '',
			   _from_pid: int = -1, 
			   _to_pid: int = -1, 
			   _room_code: String = '') -> void:
		# providing default values for serializer
		generated_t = utils.get_millis()
		event_name  = _event_name
		from_pid    = _from_pid
		to_pid      = _to_pid
		room_code   = _room_code

#
# Request to join a room. Server will reply with a JoinResponse.
#
class JoinRequest extends SignalEvent:
	func _init(_room_code: String = '') -> void:
		# from_pid and to_pid unknown until server assigns us
		super._init("join", -1, -1, _room_code)

#
# Server’s response carrying our assigned peer ID.
#
class JoinResponse extends SignalEvent:
	func _init(_from_pid: int = -1,
			   _to_pid: int = -1, 
			   _room_code: String = '') -> void:
		super._init("join_response", _from_pid, _to_pid, _room_code)

# 
# Server will broadcast this event when a new peer joins.
# 
class PeerJoinedEvent extends SignalEvent:
	@export var joined_pid : int
	func _init(_from_pid: int = -1,
			   _to_pid: int = -1, 
			   _room_code: String = '', 
			   _joined_pid: int = -1) -> void:
		super._init("peer_joined", _from_pid, _to_pid, _room_code)
		joined_pid = _joined_pid

#
# SDP offer/answer event.
#
class SdpEvent extends SignalEvent:
	@export var sdp_type:    String
	@export var sdp_content: String

	func _init(_from_pid: int = -1, 
			  _to_pid: int = -1, 
			  _room_code: String = '',
			  _sdp_type: String = '',
			  _sdp_content: String = '') -> void:
		super._init("sdp", _from_pid, _to_pid, _room_code)
		sdp_type    = _sdp_type
		sdp_content = _sdp_content

#
# ICE candidate event.
#
class IceEvent extends SignalEvent:
	@export var ice_media: String
	@export var ice_index: int
	@export var ice_name:  String

	func _init(_from_pid: int = -1,
			   _to_pid: int = -1,
			   _room_code: String = '', 
			   _ice_media: String = '', 
			   _ice_index: int = -1, 
			   _ice_name: String = '') -> void:
		super._init("ice", _from_pid, _to_pid, _room_code)
		ice_media = _ice_media
		ice_index = _ice_index
		ice_name  = _ice_name

#
func _init(_signaling : SignalServerCommunicator, _room_code) -> void:
	signaling = _signaling
	room_code = _room_code
	add_child(signaling)
	signaling.message_received.connect(_on_signaling_msg)

	multi_peer = WebRTCMultiplayerPeer.new()
	# Send the join request; server will reply with our peer_id
	var req = JoinRequest.new(room_code)
	await signaling.socket_opened
	signaling.send(JsonCC.class_to_json_string(req))

#
# Unified handler for all incoming signaling messages.
#
func _on_signaling_msg(raw: String) -> void:
	var json = JSON.new()
	if json.parse(raw) != OK:
		ls.error("Invalid JSON from signaling: " + raw)
		return

	var d  = json.data as Dictionary
	var ev = _parse_event(d)
	if ev == null:
		return

	if ev.event_name == "peer_joined":
		# ev.from_pid is the ID of the peer that just joined
		# ev.to_pid is our assigned ID
		var peer_joined = ev as PeerJoinedEvent
		ls.info("Peer joined: %d" % peer_joined.joined_pid)
		_ensure_connection(peer_joined.joined_pid)
		return

	if ev.event_name == "join_response":
		# ev.to_pid is our assigned ID
		own_peer_id = ev.to_pid
		ls.info("Join response: %d" % own_peer_id)
		multi_peer.create_mesh(own_peer_id)
		return

	if own_peer_id < 0:
		return

	if ev.to_pid != own_peer_id:
		return

	match ev.event_name:
		"sdp":
			ls.info("SDP from %d" % ev.from_pid)
			_handle_sdp(ev as SdpEvent)
		"ice":
			ls.info("ICE from %d" % ev.from_pid)
			_handle_ice(ev as IceEvent)

#
# Convert a raw Dictionary into the correct Event subclass.
#
func _parse_event(d: Dictionary) -> SignalEvent:
	match d.get("event_name", ""):
		"join_response":
			return JsonCC.json_to_class(JoinResponse, d)
		"peer_joined":
			return JsonCC.json_to_class(PeerJoinedEvent, d)
		"sdp":
			return JsonCC.json_to_class(SdpEvent, d)
		"ice":
			return JsonCC.json_to_class(IceEvent, d)
		_:
			ls.error("Unknown event type: " + str(d))
			return null

#
# Ensure a WebRTCPeerConnection exists for peer `from_pid`,
# bind its signals (after we know our own ID), and return it.
#
func _ensure_connection(from_pid: int) -> WebRTCPeerConnection:
	if connections.has(from_pid):
		return connections[from_pid]

	var pc = WebRTCPeerConnection.new()
	# add_child(pc)

	# Bind peer_id (remote) so our handlers know the target directly
	pc.session_description_created.connect(_on_local_session.bind(from_pid))
	pc.ice_candidate_created.connect(_on_local_ice.bind(from_pid))

	connections[from_pid] = pc
	assert(pc.get_connection_state() == WebRTCPeerConnection.ConnectionState.STATE_NEW)
	
	multi_peer.add_peer(pc, from_pid)

	# Let the lower-ID peer initiate the offer
	if own_peer_id < from_pid:
		pc.create_offer()

	return pc

#
# Handle incoming SDP from `ev.from_pid`
#
func _handle_sdp(ev: SdpEvent) -> void:
	var pc := _ensure_connection(ev.from_pid)
	pc.set_remote_description(ev.sdp_type, ev.sdp_content)

#
# Handle incoming ICE from `ev.from_pid`
#
func _handle_ice(ev: IceEvent) -> void:
	if connections.has(ev.from_pid):
		connections[ev.from_pid].add_ice_candidate(ev.ice_media, ev.ice_index, ev.ice_name)

#
# Local SDP ready → send to server.
# `peer_id` here is the remote peer (bound via .bind).
#
func _on_local_session(type: String, sdp: String, peer_id: int) -> void:
	var ev = SdpEvent.new(own_peer_id, peer_id, room_code, type, sdp)
	signaling.send(JsonCC.class_to_json_string(ev))
	connections[peer_id].set_local_description(type, sdp)

#
# Local ICE candidate ready → send to server.
func _on_local_ice(media: String, index: int, name: String, peer_id: int) -> void:
	var ev = IceEvent.new(own_peer_id, peer_id, room_code, media, index, name)
	signaling.send(JsonCC.class_to_json_string(ev))

#
# Poll all connections each frame to drive WebRTC.
#
func _process(delta: float) -> void:
	multi_peer.poll()
	for pc in connections.values():
		pc.poll()

	if multi_peer.get_connection_status() == WebRTCMultiplayerPeer.CONNECTION_CONNECTED or \
	   multi_peer.get_connection_status() == WebRTCMultiplayerPeer.CONNECTION_CONNECTING:
		multi_peer_connecting.emit()
