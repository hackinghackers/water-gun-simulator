@tool
extends Node
const JsonCC = preload("res://addons/JsonClassConverter/JsonClassConverter.gd")
const ConStarter = preload("res://scripts/web/web_rtc_conn_starter.gd")

class TestClass: 
	@export var a : String = "var a"
	@export var b : String = "var b"
	func prt() -> void:
		print("a: " + a + " b: " + b)
	func _init() -> void:
		self.a = "var a"
		self.b = "var b"

var test_class = TestClass.new()

func _enter_tree() -> void:
	print("entered _ready")
	#var test_sig_event = WebRTCConStarter.IceEvent.new(1, 2, "test_code", "test_media", 3, "test_ice_name")

	var test_sig_event = test_class
	test_class.prt()
	
	var test_dict = {
		"key_a" : "val_a", 
		"key_b" : "val_b"
	}
	print("type string: " + type_string(typeof(test_class)))
	print("JSON.stringify: " + JSON.stringify(test_class))
	print("JSON.stringify: " + JSON.stringify(test_dict))
	print("JsonCC: " + JsonCC.class_to_json_string(test_class))
	#print("JsonCC: " + JsonCC.class_to_json_string(test_dict))
