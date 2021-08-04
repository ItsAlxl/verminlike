class_name Mob
extends Unit

const DESPAWN_DIST_SQ := pow(350.0, 2);
const SLEEP_DIST_SQ := pow(100.0, 2);

signal gained_aggro();

var to_plr := Vector3.ZERO;
var to_plr_norm := Vector3.ZERO;
var dist_sq_to_plr := -1.0;
var dist_to_plr := -1.0;

var atk_dist_sq := 4.0;
var movt_dist_sq := 3.0625;

var is_aggro := false;

var roam_attention := 0.0;
var roam_move := false;

func _cleanup() -> void:
	Game.level.rem_mob(self);

func _ready() -> void:
	Game.request_lpc_combo(self, "_take_lpc_combo", Game.get_random_lpc_options());

func _physics_process(delta: float) -> void:
	to_plr = Game.plr.translation - translation;
	dist_sq_to_plr = to_plr.length_squared();
	
	if dist_sq_to_plr >= DESPAWN_DIST_SQ:
		_cleanup();
	else:
		sleeping = dist_sq_to_plr >= SLEEP_DIST_SQ;
	
	if sleeping || is_dead:
		if dist_to_plr > 0:
			dist_to_plr = -1;
	else:
		dist_to_plr = sqrt(dist_sq_to_plr);
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
				if dist_sq_to_plr <= atk_dist_sq && !is_attacking && can_wep_move():
					start_melee_attack();
		else:
			roam_attention -= delta;
			if roam_attention <= 0.0:
				roam_attention = rand_range(2.0, 7.0);
				roam_move = randf() > 0.3;
				head.rotation.y += rand_range(-PI / 2, PI / 2);

func is_aggro_to_plr() -> bool:
	return !sleeping && is_aggro && is_alive() && Game.plr.is_alive();

func take_atk(dmg: float, knockback: Vector2, attacker: Unit, extras := {}) -> bool:
	if attacker is Player:
		spread_aggro();
	return .take_atk(dmg, knockback, attacker, extras);

func spread_aggro() -> void:
	if !sleeping && !is_dead:
		if is_alive() && !is_aggro:
			is_aggro = true;
			emit_signal("gained_aggro");

func get_unstunned_movt() -> Vector3:
	if is_aggro_to_plr():
		if dist_sq_to_plr > movt_dist_sq && !is_attacking:
			return to_plr_norm;
	elif roam_move:
		return vector2_to_facing(Vector2(0, -1));
	return Vector3.ZERO;

func _heavy_ready() -> void:
	._heavy_ready();
	release_melee_attack();

func _on_AggroBubble_body_entered(body: PhysicsBody) -> void:
	if !sleeping && !is_dead:
		if body is Player:
			spread_aggro();
		if body.has_method("spread_aggro"):
			if body.is_aggro_to_plr():
				spread_aggro();
			else:
				if !body.is_connected("gained_aggro", self, "spread_aggro"):
					body.connect("gained_aggro", self, "spread_aggro");

func _on_AggroBubble_body_exited(body: PhysicsBody) -> void:
	if !sleeping && !is_dead:
		if body.has_method("spread_aggro"):
			if body.is_connected("gained_aggro", self, "spread_aggro"):
				body.disconnect("gained_aggro", self, "spread_aggro");
