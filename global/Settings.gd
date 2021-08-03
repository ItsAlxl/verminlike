extends Node

var data := {
	"look_sensitivity": 9,
	"master_vol": 80,
};

func set_value(key: String, val) -> void:
	data[key] = val;

func get_value(key: String, def_val = null):
	return data.get(key, def_val);
