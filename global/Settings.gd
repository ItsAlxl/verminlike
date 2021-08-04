extends Node

const CFG_SECTION = "settings";

var data := {
	"look_sensitivity": 9,
	"master_vol": 80,
	"lpc_opts": {},
	"mwep": "hammer",
};

func set_value(key: String, val) -> void:
	data[key] = val;

func get_value(key: String, def_val = null):
	return data.get(key, def_val);

func _ready() -> void:
	var cfg := ConfigFile.new();
	var err := cfg.load(_get_save_loc());
	if err == OK:
		for k in cfg.get_section_keys(CFG_SECTION):
			data[k] = cfg.get_value(CFG_SECTION, k);

func save() -> void:
	var cfg := ConfigFile.new();
	for k in data:
		cfg.set_value(CFG_SECTION, k, data[k]);
	cfg.save(_get_save_loc());

func _get_save_loc() -> String:
	return OS.get_executable_path().get_base_dir() + "/beat_and_chaff_settings.cfg";
