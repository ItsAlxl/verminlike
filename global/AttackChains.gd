extends Node

var chains := {
	"hammer": {
		"": {
			"light": "bash_down",
			"heavy": "swipe_left",
			
			"end_side": "right",
		},
		"swipe_left": {
			"heavy": "swipe_right",
			"light": "uppercut",
			
			"end_side": "left",
		},
		"uppercut": {
			"atk_extras": {
				"knockback": Vector2(0, 10),
			},
		},
		"bash_down": {
			"atk_extras": {
				"dmg": 20,
			},
		},
	},
};

func get_base_anim(chain: String, mode: String) -> String:
	return chains[chain][""][mode];

func _safe_get(chain: String, anim: String, key: String, def_val):
	if chains.has(chain):
		return chains[chain].get(anim, chains[chain][""]).get(key, def_val);
	return def_val;

func get_next_anim(chain: String, mode: String, anim := "") -> String:
	return _safe_get(chain, anim, mode, get_base_anim(chain, mode));

func get_anim_ending_side(chain: String, anim := "") -> String:
	return _safe_get(chain, anim, "end_side", "right");

func get_attack_extras(chain: String, anim := "") -> Dictionary:
	return _safe_get(chain, anim, "atk_extras", {});
