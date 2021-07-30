class_name Weapon
extends Spatial

# it's for a hack :)
const RESET_AREA_OVERLAP_OFFSET := Vector3(0, 100, 0);

onready var HitArea := $HitArea;

export var dmg := 0.0;
export var knockback := Vector2(0.0, 0.0);

var is_reporting_hits := false setget set_hits_active;
var is_plr_wep := true setget set_plr_controlled;
var unit_owner: Unit = null;

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
	# Ensure subsequent attacks will trigger _on_Oucher_body_entered
	# even though they normally wouldn't actually leave the body
	# I told you it was a hack :)
	if a:
		HitArea.translation = Vector3.ZERO;
	else:
		HitArea.translation = RESET_AREA_OVERLAP_OFFSET;
	
	is_reporting_hits = a;
	HitArea.monitoring = a;

func get_atk_extras() -> Dictionary:
	return {};

func _on_HitArea_body_entered(body: PhysicsBody):
	if body.has_method("take_atk"):
		body.take_atk(dmg, knockback, unit_owner, get_atk_extras());
