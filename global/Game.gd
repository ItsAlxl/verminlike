extends Node

const MAX_LPC_THREADS := 10;
const LPC_ORDER := ["base", "shoes", "legs", "tops", "belts", "hats", "gloves"];
const LPC_IMPORT_FLAGS := 0;
var lpc_options := {
	"base": {"base": preload("res://unit/lpc/base/masc_human.png")},
	"belts": {},
	"gloves": {},
	"hats": {},
	"legs": {},
	"shoes": {},
	"tops": {},
};
var _lpc_request_queue := [];
var _lpc_threads := [];
var _lpc_queue_mutex := Mutex.new();

var plr: Player;
var level: Spatial;

func _ready() -> void:
	randomize();
	
	for _i in range(MAX_LPC_THREADS):
		var t := Thread.new();
		t.start(self, "_check_lpc_req_queue", _lpc_queue_mutex);
		_lpc_threads.append(t);

const LPC_ART_DIR := "res://unit/lpc/";
func get_lpc_options(category: String) -> Dictionary:
	
	if lpc_options[category].empty():
		lpc_options[category]["none"] = null;
		
		var dir := Directory.new();
		dir.open(LPC_ART_DIR + category);
		dir.list_dir_begin(true, true);
		while true:
			var f := dir.get_next();
			if f == "":
				break;
			elif f.ends_with(".png"):
				lpc_options[category][f.get_basename().get_file()] = load(dir.get_current_dir() + "/" + f);
	
	return lpc_options[category];

func get_lpc_tex(category: String, opt: String) -> Texture:
	return get_lpc_options(category)[opt];
func get_random_lpc_tex(category: String) -> Texture:
	var opt_keys := get_lpc_options(category).keys();
	return get_lpc_tex(category, opt_keys[randi() % opt_keys.size()]);

func get_random_lpc_options() -> Dictionary:
	var opts := {};
	for cat in LPC_ORDER:
		opts[cat] = get_random_lpc_tex(cat);
	return opts;

func get_lpc_combo_texture(chosen_opts := {}) -> Texture:
	var img := preload("res://unit/lpc/base/masc_human.png").get_data();
	
	for cat in LPC_ORDER:
		if chosen_opts.has(cat):
			if chosen_opts[cat] != null:
				img.blend_rect(chosen_opts[cat].get_data(), Rect2(Vector2.ZERO, img.get_size()), Vector2.ZERO);
	
	var tex := ImageTexture.new();
	tex.create_from_image(img, LPC_IMPORT_FLAGS);
	return tex;

func request_lpc_combo(cb_obj: Object, cb_func: String, opts: Dictionary) -> void:
	_lpc_request_queue.append([cb_obj, cb_func, opts]);

func _check_lpc_req_queue(mutex: Mutex) -> void:
	while true:
		mutex.lock();
		if _lpc_request_queue.empty():
			mutex.unlock();
			OS.delay_msec(100);
		else:
			var req: Array = _lpc_request_queue.pop_back();
			mutex.unlock();
			_perf_lpc_request(req);

func _perf_lpc_request(req: Array) -> void:
	req[0].call(req[1], get_lpc_combo_texture(req[2]));
