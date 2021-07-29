class_name Mob
extends Unit

var to_plr := Vector3.ZERO;
var to_plr_norm := Vector3.ZERO;
var dist_to_plr := -1.0;
var to_plr_view := 0.0;

var attack_range := 2.0;
var movt_range := 1.75;
var instant_aggro_range := 7.5;

func _physics_process(delta: float) -> void:
	if !is_dead:
		to_plr = Game.plr.translation - translation;
		dist_to_plr = to_plr.length();
		to_plr_norm = to_plr / dist_to_plr;
		to_plr_view = get_arc_dot(Game.plr);
		
		var plr_perspective_cross := Game.plr._get_facing_2D().cross(_get_facing_2D());
		var plr_perspective_dot := Game.plr._get_facing_2D().dot(_get_facing_2D());
		var is_persp_vert_dom := abs(plr_perspective_dot) > 0.75 * abs(plr_perspective_cross);
		if is_persp_vert_dom:
			if plr_perspective_dot > 0:
				LPCLeader.facing_dir = 0;
			else:
				LPCLeader.facing_dir = 2;
		else:
			if plr_perspective_cross > 0:
				LPCLeader.facing_dir = 3;
			else:
				LPCLeader.facing_dir = 1;
		
		._physics_process(delta);
		
		if is_aggro_to_plr() && !is_attacking:
			# Look at the player
			head.look_at(Game.plr.translation + head.translation, Vector3.UP);
			head.rotation.x = 0;
			head.rotation.z = 0;
			pitch.look_at(Game.plr.translation + head.translation, Vector3.UP);
			pitch.rotation.y = 0;
			pitch.rotation.z = 0;
			pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -90, 90);
			
			# Attack if close enough
			if dist_to_plr <= attack_range && can_wep_move():
				start_melee_attack();

func is_aggro_to_plr() -> bool:
	return is_alive() && (to_plr_view > 0.0 || dist_to_plr <= instant_aggro_range);

func get_unstunned_movt() -> Vector3:
	if is_aggro_to_plr() && dist_to_plr > movt_range && !is_attacking:
		return to_plr_norm;
	return Vector3.ZERO;

func _heavy_ready() -> void:
	._heavy_ready();
	release_melee_attack();
