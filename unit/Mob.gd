class_name Mob
extends Unit

signal gained_aggro();

var to_plr := Vector3.ZERO;
var to_plr_norm := Vector3.ZERO;
var dist_to_plr := -1.0;

var attack_range := 2.0;
var movt_range := 1.75;

var is_aggro := false;

var roam_attention := 0.0;
var roam_move := false;

func _physics_process(delta: float) -> void:
	if !is_dead:
		to_plr = Game.plr.translation - translation;
		dist_to_plr = to_plr.length();
		to_plr_norm = to_plr / dist_to_plr;
		
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
	
	if !is_dead:
		if is_aggro_to_plr():
			if !is_attacking:
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
		else:
			roam_attention -= delta;
			if roam_attention <= 0.0:
				roam_attention = rand_range(2.0, 7.0);
				roam_move = randf() > 0.3;
				head.rotation.y += rand_range(-PI / 2, PI / 2);

func is_aggro_to_plr() -> bool:
	return is_aggro && is_alive() && Game.plr.is_alive();

func take_atk(dmg: float, knockback: Vector2, attacker: Unit, extras := {}) -> void:
	if attacker is Player:
		spread_aggro();
	.take_atk(dmg, knockback, attacker, extras);

func spread_aggro() -> void:
	if is_alive() && !is_aggro:
		is_aggro = true;
		emit_signal("gained_aggro");

func get_unstunned_movt() -> Vector3:
	if is_aggro_to_plr():
		if dist_to_plr > movt_range && !is_attacking:
			return to_plr_norm;
	elif roam_move:
		return vector2_to_facing(Vector2(0, -1));
	return Vector3.ZERO;

func _heavy_ready() -> void:
	._heavy_ready();
	release_melee_attack();

func _on_AggroBubble_body_entered(body: PhysicsBody) -> void:
	if body is Player:
		spread_aggro();
	if body.has_method("spread_aggro"):
		if body.is_aggro_to_plr():
			spread_aggro();
		else:
			body.connect("gained_aggro", self, "spread_aggro");

func _on_AggroBubble_body_exited(body: PhysicsBody) -> void:
	if body.has_method("spread_aggro"):
		if body.is_connected("gained_aggro", self, "spread_aggro"):
			body.disconnect("gained_aggro", self, "spread_aggro");
