class_name MeleeWeapon
extends Weapon

export var attack_chain := "";

var current_attack := "" setget set_current_atk;
var hit_so_far := [];

func _init() -> void:
	wep_type = "MELEE";

func _on_HitArea_body_entered(body: PhysicsBody) -> void:
	if body.has_method("take_atk") && !hit_so_far.has(body) && hit_so_far.size() < get_atk_extras().get("max_hits", INF):
		hit_so_far.append(body);
		atk_unit(body);
		AudioHit.play();

# it's for a hack :)
const RESET_AREA_OVERLAP_OFFSET := Vector3(-100, -100, -100);
func set_hits_active(a: bool) -> void:
	HitArea.monitoring = a;
	
	# Ensure subsequent attacks will trigger _on_HitArea_body_entered
	# even though they normally wouldn't actually leave the body
	# I told you it was a hack :)
	if a:
		HitArea.translation = Vector3.ZERO;
		hit_so_far.clear();
	else:
		HitArea.translation = RESET_AREA_OVERLAP_OFFSET;
	
	is_reporting_hits = a;

func set_current_atk(ca: String) -> void:
	current_attack = ca;

func get_next_atk_anim(atk_anim_name: String, mode: String) -> String:
	return AttackChains.get_next_anim(attack_chain, mode, atk_anim_name);

func get_anim_ending_side(atk_anim_name: String) -> String:
	return AttackChains.get_anim_ending_side(attack_chain, atk_anim_name);

func get_anim_preptype(atk_anim_name := "") -> String:
	return AttackChains.get_anim_prep_type(attack_chain, atk_anim_name);

func get_atk_extras() -> Dictionary:
	return AttackChains.get_attack_extras(attack_chain, current_attack);
