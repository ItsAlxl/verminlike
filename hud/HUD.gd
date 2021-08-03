extends CanvasLayer

# General HUD
const MIN_DB = -45.0;
const MAX_DB = 5.0;
var ighud_enabled := false;

func enable(e: bool) -> void:
	ighud_enabled = e;
	show_ingame_opts(false);
	$InGameHUD.visible = e;

func take_ammo(at: int, of: int) -> void:
	$InGameHUD/Ammo/RevolverAmmo.set_max(of);
	$InGameHUD/Ammo/RevolverAmmo.set_now(at);

func take_ammo_pool(ap: int) -> void:
	$InGameHUD/Ammo/InvertPool/AmmoPool.set_num_bullets(ap);

func _input(ev: InputEvent) -> void:
	if ighud_enabled:
		# Capture/release mouse
		if ev.is_action_pressed("ui_cancel"):
			show_ingame_opts(!get_tree().paused);

func show_ingame_opts(s: bool) -> void:
	get_tree().paused = s;
	$InGameOpts.visible = s;
	$InGameHUD.visible = !s;
	
	if s:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	elif ighud_enabled:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _on_BtnResume_pressed():
	show_ingame_opts(false);

func change_vol(val: float) -> void:
	$InGameOpts/VBoxMenu/LblVol/NUDVol.value = val;
	$InGameOpts/VBoxMenu/SliderVol.value = val;
	Settings.set_value("master_vol", val);
	
	var db := -200;
	if val > 0.0:
		db = lerp(MIN_DB, MAX_DB, val * 0.01);
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db);

func change_sens(val: float) -> void:
	$InGameOpts/VBoxMenu/LblSensitivy/NUDSensitivity.value = val;
	$InGameOpts/VBoxMenu/SliderSensitivity.value = val;
	Settings.set_value("look_sensitivity", val);

func _on_BtnMainMenu_pressed():
	change_scene("menu");

func _on_BtnQuit_pressed():
	get_tree().quit();

# Scene transition

func _ready():
	set_process(false);
	change_sens(Settings.get_value("look_sensitivity"));

const TITLE_TO_PATH := {
	"ATG": "res://level/level.tscn",
	"DBG": "res://level/dbg_level.tscn",
	"menu": "res://menu/main_menu.tscn",
};
var transit_info := {};
var transit_loader: ResourceInteractiveLoader = null;
func change_scene(scene_title: String, cb := "", args := []) -> void:
	if scene_title in TITLE_TO_PATH:
		change_scene_path(TITLE_TO_PATH[scene_title], cb, args);
	else:
		print("Trying to change to unpathed scene: %s" % scene_title);

func change_scene_path(scene_path: String, cb := "", args := []) -> void:
	transit_info = {"scene_path": scene_path, "cb": cb, "cb_args": args};
	$SceneTransit/Transit.play("transit");

func _perf_transit() -> void: # Called in animation
# warning-ignore:return_value_discarded
	transit_loader = ResourceLoader.load_interactive(transit_info["scene_path"]);
	get_tree().paused = true;
	set_process(true);

func _process(delta: float) -> void:
	if transit_loader == null:
		get_tree().paused = false;
		set_process(false);
		yield(get_tree(), "idle_frame");
		call_deferred("_perf_transit_callback");
		yield(get_tree(), "idle_frame");
		$SceneTransit/Transit.call_deferred("play", "detransit");
	else:
		var err := transit_loader.poll()
		if err == ERR_FILE_EOF: # Finished loading.
			var resource := transit_loader.get_resource();
			transit_loader = null;
			get_tree().change_scene_to(resource);
		elif err != OK:
			transit_loader = null;

func _perf_transit_callback() -> void:
	var cb: String = transit_info.get("cb", "");
	var args: Array = transit_info.get("cb_args", []);
	if !cb.empty() && !args.empty():
		get_tree().get_current_scene().callv(cb, args);
