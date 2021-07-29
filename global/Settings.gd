extends Node

var data := {
	"mouse_sensitivity": 0.0009,
	"master_volume": 1.0,
}

func set_data(key: String, val) -> void:
	data[key] = val;

func get_data(key: String, def_val = null):
	return data.get(key, def_val);
