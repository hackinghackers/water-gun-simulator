class_name MapManager extends Node3D
var map_name : String
var spawn_pts : Array[Vector3]
var map_path : String
var map_scene : PackedScene
var map_inst : Node3D
var spawn_pts_node : Node
var ls := LogStream.new("map (%s)" % map_name)

func _init(_map_name : String) -> void:
	map_name = _map_name

func get_rand_spawn_pt() -> Vector3:
	var rand_index := int(randf_range(0, spawn_pts.size() - 1))
	return spawn_pts[rand_index]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map_path = "res://maps/%s.tscn" % map_name
	ls.err_cond_false(ResourceLoader.exists(map_path), "map does not exist: " + map_path)
	ls.info("loading map: " + map_path)
	map_scene = load(map_path)
	map_inst = map_scene.instantiate()
	spawn_pts_node = map_inst.get_node("Map/SpawnPts")

	var node_children := spawn_pts_node.get_children()
	spawn_pts = []
	for child in node_children:
		ls.err_cond_false(child is Node3D, "child is not a Node3D")
		var _child := child as Node3D
		spawn_pts.append(_child.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
