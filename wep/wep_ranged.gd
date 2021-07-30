extends Spatial

onready var ShootRay := $ShootRay;

export var dmg := 0.0;
export var knockback := Vector2(0.0, 0.0);
export var cone := Vector2(0.0, 0.0);
export var max_dist := 10.0;
export var fire_cd := 1.2;
export var mag_size := 6;
export var reload_amt := 1;
export var reload_time := 0.5;

var unit_owner: Unit = null;
var ammo_now := -1;

func setup(uown: Unit) -> void:
	unit_owner = uown;
	set_plr_controlled(uown is Player);
	ammo_now = mag_size;

var is_plr_wep := true setget set_plr_controlled;
func set_plr_controlled(pc: bool) -> void:
	is_plr_wep = pc;
	if pc:
		ShootRay.collision_mask = 0b101;
	else:
		ShootRay.collision_mask = 0b11;

func fire() -> void:
	var spread_x := rand_range(-cone.x, cone.x);
	var spread_y := rand_range(-cone.y, cone.y);
	ShootRay.cast_to = Vector3(max_dist, spread_y, spread_x);
	ShootRay.force_raycast_update();
