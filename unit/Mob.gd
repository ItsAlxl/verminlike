class_name Mob
extends Unit

const DESPAWN_DIST_SQ := pow(350.0, 2);
const SLEEP_DIST_SQ := pow(100.0, 2);
const NUM_WALLAVOID_RAYCASTS := 8;
const WALLAVOID_RAYCAST_HALF_ARC := PI / NUM_WALLAVOID_RAYCASTS;

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

func _setup_weps() -> void:
	WepHand.add_child(Game.get_random_wep_pscene().instance());
	._setup_weps();

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
				var rot := get_wallavoid_raycast_random_angle(find_noncolliding_wallavoid_raycast());
				if is_nan(rot):
					roam_move = false;
				else:
					roam_attention = rand_range(2.0, 7.0);
					roam_move = randf() > 0.3;
					
					head.rotation.y = rot;

func find_noncolliding_wallavoid_raycast(start_at := -1) -> int:
	if start_at < 0:
		start_at = randi() % NUM_WALLAVOID_RAYCASTS;
	
	for i in range(NUM_WALLAVOID_RAYCASTS):
		var idx := (start_at + i) % NUM_WALLAVOID_RAYCASTS;
		if !$AvoidWalls.get_child(idx).is_colliding():
			return idx;
	return -1;

func get_wallavoid_raycast_random_angle(rc_idx: int) -> float:
	if rc_idx < 0:
		return NAN;
	
	var left := -WALLAVOID_RAYCAST_HALF_ARC;
	var right := WALLAVOID_RAYCAST_HALF_ARC;
	if !$AvoidWalls.get_child(posmod(rc_idx + 1, NUM_WALLAVOID_RAYCASTS)).is_colliding():
		right *= 2;
	if !$AvoidWalls.get_child(posmod(rc_idx - 1, NUM_WALLAVOID_RAYCASTS)).is_colliding():
		left *= 2;
	
	var ray: Vector3 = $AvoidWalls.get_child(rc_idx).cast_to;
	return Vector2(ray.x, ray.z).angle() + rand_range(left, right);

func get_nearest_wallavoid_raycast_to(angle: float) -> int:
	var best_diff := INF;
	var best_idx := -1;
	for i in range(NUM_WALLAVOID_RAYCASTS):
		var rc_cast: Vector3 = $AvoidWalls.get_child(i).cast_to;
		var rc_angle_diff := fposmod(angle - Vector2(rc_cast.x, rc_cast.z).angle(), TAU);
		if rc_angle_diff < best_diff:
			best_diff = rc_angle_diff;
			best_idx = i;
	return best_idx;

func is_aggro_to_plr() -> bool:
	return !sleeping && is_aggro && is_alive() && Game.plr.is_alive();

func take_atk(dmg: float, knockback: Vector2, attacker: Unit, extras := {}) -> bool:
	if attacker is Player:
		spread_aggro();
	return .take_atk(dmg, knockback, attacker, extras);

func spread_aggro() -> void:
	if !sleeping && !is_dead && is_alive() && !is_aggro:
		is_aggro = true;
		for body in $Head/AggroBubble.get_overlapping_bodies():
			if body.has_method("spread_aggro"):
				body.spread_aggro();

func get_naive_movt() -> Vector3:
	if is_aggro_to_plr():
		if dist_sq_to_plr > movt_dist_sq && !is_attacking:
			return to_plr_norm;
	elif roam_move:
		return vector2_to_facing(Vector2(0, -1));
	return Vector3.ZERO;

func get_unstunned_movt() -> Vector3:
	var movt := get_naive_movt();
	if movt != Vector3.ZERO:
		if $AvoidWalls.get_child(get_nearest_wallavoid_raycast_to(Vector2(movt.x, movt.z).angle())).is_colliding():
			return Vector3.ZERO;
	return movt;


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
