class_name Weapon
extends Spatial

onready var HitArea: Area = $HitArea;
onready var AudioHit := $AudioHit;

export var dmg := 0.0;
export var knockback := Vector2(0.0, 0.0);

var is_reporting_hits := false setget set_hits_active;
var is_plr_wep := true setget set_plr_controlled;
var unit_owner: Unit = null;

var wep_type := "BASE";

func setup(uown: Unit) -> void:
	unit_owner = uown;
	set_plr_controlled(uown is Player);
	set_hits_active(false);

func set_plr_controlled(pc: bool) -> void:
	is_plr_wep = pc;
	if pc:
		HitArea.collision_layer = 0b1000;
		HitArea.collision_mask = 0b100;
	else:
		HitArea.collision_layer = 0b10000;
		HitArea.collision_mask = 0b10;

func set_hits_active(a: bool) -> void:
	HitArea.monitoring = a;
	is_reporting_hits = a;

func get_atk_extras() -> Dictionary:
	return {};

func _on_HitArea_body_entered(_body: PhysicsBody) -> void:
	pass;

func atk_unit(u: Unit) -> void:
	u.take_atk(dmg, knockback, unit_owner, get_atk_extras());
