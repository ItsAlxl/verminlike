extends CanvasLayer

# General HUD

func enable(e: bool) -> void:
	$InGameHUD.visible = e;

func take_ammo(at: int, of: int) -> void:
	$InGameHUD/RevolverAmmo.set_max(of);
	$InGameHUD/RevolverAmmo.set_now(at);

func _input(ev: InputEvent) -> void:
	if $InGameHUD.visible:
		# Capture/release mouse
		if ev.is_action_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

# Scene transition

func _ready():
	set_process(false);

const TITLE_TO_PATH := {
	"ATG": "res://level/level.tscn",
	"DBG": "res://level/dbg_level.tscn",
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
	set_process(true);

func _process(delta: float) -> void:
	if transit_loader == null:
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

