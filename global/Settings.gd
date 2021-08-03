extends Node

var data := {
	"mouse_sensitivity": 0.0009,
	"master_vol": 80,
};

func set_value(key: String, val) -> void:
	data[key] = val;

func get_value(key: String, def_val = null):
	return data.get(key, def_val);
