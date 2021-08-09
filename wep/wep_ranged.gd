class_name RangedWeapon
extends Weapon

onready var AudioDry = $WepArt/AudioDry
onready var AudioReload = $WepArt/AudioReload;
onready var AudioReloadDone = $WepArt/AudioReloadDone;

export var spread := Vector2(0.0, 0.0);
export var fire_cd := 0.1;
export var mag_size := 600;
export var reload_amt := 1;
export var reload_time := 0.25;
export var max_hits := 1;
export var atk_extras := {};

var ammo_now := -1;

var fire_cd_now := 0.0;
var reload_time_now := 0.0;
var _fire_frame := false;

var targs := [];

onready var muzzle_transl := HitArea.translation;
var eyeline_adjusted := false;

func _init() -> void:
	wep_type = "RANGED";

func _ready() -> void:
	ammo_now = mag_size;

func setup(uown: Unit) -> void:
	.setup(uown);
	report_ammo_to_hud();

func _set_owner_can_move_wep(a: bool) -> void:
	unit_owner.set_allow_wep_movt(a);

func _physics_process(delta: float) -> void:
	if fire_cd_now > 0:
		fire_cd_now -= delta;
	if reload_time_now > 0:
		reload_time_now -= delta;
	
	if _fire_frame:
		_fire_frame = false;
		
		var hit_units := [];
		var num_hits = targs.size();
		if max_hits > -1:
			num_hits = min(max_hits, num_hits);
		for i in range(num_hits):
			_insort_hit(hit_units, {
				"unit": targs[i],
				"dist_sq": (targs[i].translation - unit_owner.translation).length_squared(),
			});
		
		for h in hit_units:
			atk_unit(h.unit);

func set_hits_active(_a: bool) -> void:
	pass;

func report_ammo_to_hud() -> void:
	if unit_owner == Game.plr:
		HUD.take_ammo(ammo_now, mag_size);

func fire() -> int:
	if ammo_now > 0:
		if fire_cd_now <= 0:
			_fire_frame = true;
			ammo_now -= 1;
			report_ammo_to_hud();
			
			fire_cd_now = fire_cd;
			AudioHit.play();
			$AnimGun.play("recoil");
			return 0;
	else:
		AudioDry.play();
		return 1;
	return 2;

func reload() -> int:
	if reload_time_now <= 0:
		reload_time_now = reload_time;
		if ammo_now < mag_size:
			ammo_now = int(min(ammo_now + reload_amt, mag_size));
			AudioReload.play();
			report_ammo_to_hud();
			return 0;
		else:
			AudioReloadDone.play();
			return 1;
	return 2;

func set_eyeline_adjust(a: bool) -> void:
	if a:
		remove_child(HitArea);
		unit_owner.pitch.add_child(HitArea);
		HitArea.translation = Vector3.ZERO;
		HitArea.rotation.y = -PI / 2;
	else:
		unit_owner.pitch.remove_child(HitArea);
		add_child(HitArea);
		HitArea.translation = muzzle_transl;
		HitArea.rotation.y = 0;
	eyeline_adjusted = a;

func _on_HitArea_body_entered(body: PhysicsBody) -> void:
	if body.has_method("take_atk"):
		targs.append(body);
func _on_HitArea_body_exited(body: PhysicsBody) -> void:
	if body.has_method("take_atk"):
		targs.erase(body);

func _insort_hit(into: Array, elm: Dictionary) -> void:
	var low := 0;
	var high := into.size();
	while low < high:
		var mid := int(low + high) / 2;
		if into[mid].get("dist_sq") < elm.get("dist_sq"):
			low = mid + 1;
		else:
			high = mid;
	into.insert(low, elm);

func get_atk_extras() -> Dictionary:
	return atk_extras;


