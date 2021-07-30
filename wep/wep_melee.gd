class_name MeleeWeapon
extends Weapon

export var attack_chain := "";

var current_attack := "" setget set_current_atk;

func set_current_atk(ca: String) -> void:
	current_attack = ca;

func get_next_atk_anim(atk_anim_name: String, mode: String) -> String:
	return AttackChains.get_next_anim(attack_chain, mode, atk_anim_name);

func get_anim_ending_side(atk_anim_name: String) -> String:
	return AttackChains.get_anim_ending_side(attack_chain, atk_anim_name);

func get_atk_extras() -> Dictionary:
	return AttackChains.get_attack_extras(attack_chain, current_attack);
