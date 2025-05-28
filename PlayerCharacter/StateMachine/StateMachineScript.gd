extends Node

@export var initialState : State

var currState : State
var currStateName  : String
var states : Dictionary = {}

@onready var charRef : CharacterBody3D = $".."
var ls = LogStream.new("StateMachine", LogStream.LogLevel.DEBUG)

# func _ready():
# 	rpc_ready.rpc()

func _ready():
	#get all the state childrens
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(onStateChildTransition.rpc)
			
	#if initial state, transition to it
	if initialState:
		initialState.enter(charRef)
		currState = initialState
		currStateName = currState.stateName

func reconnectTransition():
	#connect all the transitions of the states
	ls.dbg("reconnecting state transitions by peer %d" % get_tree().get_multiplayer().get_unique_id())
	ls.dbg("all connected peers: %s" % get_tree().get_multiplayer().get_peers())
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.disconnect(onStateChildTransition.rpc)
			child.transitioned.connect(onStateChildTransition.rpc)

@rpc("any_peer", "call_remote")
func test_rpc():
	#this is just a test rpc to see if the rpc works
	ls.dbg("test_rpc called by peer %d" % get_tree().get_multiplayer().get_unique_id())
	ls.dbg("all connected peers: %s" % get_tree().get_multiplayer().get_peers())

func _process(delta : float):
	rpc_process.rpc(delta)

@rpc("any_peer", "call_local")		
func rpc_process(delta: float):
	if currState: currState.update(delta)
	
func _physics_process(delta: float):
	rpc_physics_process.rpc(delta)
	
@rpc("any_peer", "call_local")
func rpc_physics_process(delta: float):
	if currState: currState.physics_update(delta)

@rpc("any_peer", "call_local", "reliable")
func onStateChildTransition(state : State, newStateName : String):
	#manage the transition from one state to another
	
	if state != currState: return
	ls.dbg("state child transtion of peer %d got called" % get_tree().get_multiplayer().get_unique_id())
	ls.dbg("all connected peers: %s" % get_tree().get_multiplayer().get_peers())

	var newState = states.get(newStateName.to_lower())
	if !newState: return
	
	#exit the current state
	if currState: currState.exit()
	
	#enter the new state
	newState.enter(charRef)
	
	currState = newState
	currStateName = currState.stateName
