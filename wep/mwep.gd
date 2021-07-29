class_name MeleeWeapon
extends Spatial

onready var HitArea := $Oucher;

export var dmg := 5.0;
export var knockback := Vector2(6.0, 2.0);
export var attack_chain := "hammer";

var is_reporting_hits := false setget set_hits_active;
var is_plr_wep := true setget set_plr_controlled;
var unit_owner: Unit = null;
var current_attack := "" setget set_current_atk;

# it's for a hack :)
const RESET_AREA_OVERLAP_OFFSET := Vector3(0, 100, 0);

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

func set_current_atk(ca: String) -> void:
	current_attack = ca;

func _on_Oucher_body_entered(body: PhysicsBody):
	if body.has_method("take_atk"):
		body.take_atk(dmg, knockback, unit_owner, AttackChains.get_attack_extras(attack_chain, current_attack));

func get_next_atk_anim(atk_anim_name: String, mode: String) -> String:
	return AttackChains.get_next_anim(attack_chain, mode, atk_anim_name);

func get_anim_ending_side(atk_anim_name: String) -> String:
	return AttackChains.get_anim_ending_side(attack_chain, atk_anim_name);
