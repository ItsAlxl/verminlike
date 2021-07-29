class_name Unit
extends RigidBodyController

export var hp_max := 100.0;
var hp_now: float = -1.0;

onready var OverlapDetect := $OverlapDetect;
onready var WepAnims := $animWeps;
onready var StunTimer := $StunTimer;
onready var LPCLeader := $LPCLeader;
onready var LPCAutoAdv := $LPCAutoAdvance;
var push_away_overlap_force := 25.0;

var block_arc := 0.5; # 1 is no arc, -1 is full circle (based on dot product)

var is_attacking := false;
var current_chain_anim := "";
var next_atk_mode := "";
var next_prepare := "right";

var is_blocking := false setget set_is_blocking;
var block_start_time := -1;
var is_stunned := false;
var is_dead := false;

var _queue_block := false;
var _queue_unblock := false;
var _queue_atk_start := false;
var _queue_atk_release := false;

var allow_wep_movt := true setget set_allow_wep_movt, can_wep_move;

export var stun_on_hit := 0.25;

func get_wep():
	return $Head/Pitch/wep;

func _ready() -> void:
	head.rotation.y = rotation.y;
	rotation.y = 0;
	
	get_wep().setup(self);
	set_lpc_anim("IDLE");
	hp_now = hp_max;

func _physics_process(_delta: float) -> void:
	var push_away := Vector3.ZERO;
	for overlap in OverlapDetect.get_overlapping_areas():
		if overlap.has_method("get_unit"):
			var ol: Vector3 = translation - overlap.get_unit().translation;
			ol.y = 0;
			push_away += ol.normalized() * push_away_overlap_force;
	if push_away != Vector3.ZERO:
		add_central_force(push_away);

func set_allow_wep_movt(a: bool) -> void:
	allow_wep_movt = a;
	
	if a:
		if is_attacking:
			is_attacking = false;
		if !is_dead:
			set_lpc_anim("IDLE");
		
		if _queue_atk_start:
			start_melee_attack();
		elif _queue_block:
			start_block();
		elif _queue_unblock:
			end_block();

func reset_attack_chain() -> void:
	if !is_dead:
		LPCLeader.adv_anim();
	current_chain_anim = "";
	next_prepare = "right";

func can_wep_move() -> bool:
	return allow_wep_movt;

func blocks_preventing_attack() -> bool:
	return is_blocking || _queue_block || WepAnims.current_animation == "block_start";

func start_melee_attack() -> void:
	if !blocks_preventing_attack():
		if !is_attacking && can_wep_move():
			is_attacking = true;
			_queue_atk_start = false;
			next_atk_mode = "light";
			set_lpc_anim("SWIPE");
			WepAnims.play("prepare_" + next_prepare);
		else:
			_queue_atk_start = true;
			_queue_unblock = false;
			_queue_block = false;

func _allow_atk_release() -> void:
	LPCLeader.adv_anim();
	if _queue_atk_release:
		release_melee_attack();

func release_melee_attack() -> void:
	if !blocks_preventing_attack():
		if _queue_atk_start:
			_queue_atk_release = true;
		else:
			_queue_atk_release = false;
			
			LPCLeader.apex_swipe_anim();
			var attack_anim: String = get_wep().get_next_atk_anim(current_chain_anim, next_atk_mode);
			next_atk_mode = "";
			
			next_prepare = get_wep().get_anim_ending_side(attack_anim);
			get_wep().set_current_atk(attack_anim);
			WepAnims.play(attack_anim);
			current_chain_anim = attack_anim;

func set_is_blocking(b: bool) -> void:
	is_blocking = b;
	if b:
		block_start_time = OS.get_ticks_msec();

func start_block() -> void:
	if _queue_unblock:
		_queue_unblock = false;
	else:
		if can_wep_move():
			_queue_block = false;
			reset_attack_chain();
			WepAnims.play("block_start");
		elif next_atk_mode != "heavy":
			_queue_block = true;
			_queue_atk_start = false;
			_queue_atk_release = false;

func end_block() -> void:
	if _queue_block:
		_queue_block = false;
	else:
		if can_wep_move():
			_queue_unblock = false;
			if is_blocking && WepAnims.current_animation != "block_end":
				WepAnims.play("block_end");
		else:
			_queue_unblock = true;

func _get_facing_2D() -> Vector2:
	return Vector2(0, -1).rotated(-head.rotation.y);
func _get_facing_transl() -> Vector3:
	return translation;
func get_arc_dot(u: Unit) -> float:
	var dir := u.translation - _get_facing_transl();
	return _get_facing_2D().dot(Vector2(dir.x, dir.z).normalized());
func get_arc_cross(u: Unit) -> float:
	var dir := u.translation - _get_facing_transl();
	return _get_facing_2D().cross(Vector2(dir.x, dir.z).normalized());

const BASE_COUNTER_STUN := 2.0;
const BASE_COUNTER_KNOCKBACK := Vector2(3.0, 1.5);
func take_atk(dmg: float, knockback: Vector2, attacker: Unit, extras := {}) -> void:
	if is_blocking && get_arc_dot(attacker) >= block_arc:
		if get_block_age() < 200:
			attacker.take_knockback(BASE_COUNTER_KNOCKBACK + extras.get("counter_knockback", Vector2.ZERO), translation);
			attacker.take_dmg(extras.get("counter_dmg", 0.0));
			attacker.stun(BASE_COUNTER_STUN + extras.get("counter_stun", 0.0));
	else:
		stun(stun_on_hit + extras.get("stun", 0.0));
		take_dmg(dmg + extras.get("dmg", 0.0));
		take_knockback(knockback + extras.get("knockback", Vector2.ZERO), attacker.translation);

func take_dmg(dmg: float) -> void:
	hp_now -= dmg;
	if hp_now <= 0:
		die();

const CORPSE_COL_LAYER := 0b100000;
const CORPSE_COL_MASK := 0b1;
func die() -> void:
	if !is_dead:
		is_dead = true;
		
		set_lpc_anim("DEAD");
		$ParticlesBleed.emitting = true;
		
		WepAnims.play("reset");
		get_wep().visible = false;
		OverlapDetect.enable(false);
		
		collision_layer = CORPSE_COL_LAYER;
		collision_mask = CORPSE_COL_MASK;

func is_alive() -> bool:
	return !is_dead;

func take_knockback(knockback: Vector2, away_from: Vector3) -> void:
	var knockback_dir := translation - away_from;
	knockback_dir.y = 0;
	knockback_dir = knockback.x * knockback_dir.normalized();
	knockback_dir.y = knockback.y;
	apply_central_impulse(knockback_dir);

func get_block_age() -> int:
	if is_blocking:
		return OS.get_ticks_msec() - block_start_time;
	return -1;

# If duration < 0, nothing happens
# If duration >= 0, interrupt
# If duration > 0, prevent actions for duration
# Additional stuns are not additive; they replace remaining time if longer
func stun(duration := 0.0) -> void:
	if duration >= 0.0:
		reset_attack_chain();
		set_allow_wep_movt(false);
		WepAnims.play("reset");
		
		_queue_atk_release = false;
		_queue_atk_start = false;
		_queue_block = false;
		_queue_unblock = false;
		
		is_stunned = true;
		if duration > StunTimer.time_left:
			StunTimer.start(duration);
		elif StunTimer.time_left == 0.0:
			unstun();

func _on_StunTimer_timeout():
	unstun();

func unstun() -> void:
	is_stunned = false;
	set_allow_wep_movt(true);

func get_movt_vect() -> Vector3:
	if is_dead:
		return Vector3.ZERO;
	
	var movt := Vector3.ZERO;
	if !is_stunned:
		movt = get_unstunned_movt();
	
	if LPCLeader.current_anim == "MOVE":
		if movt == Vector3.ZERO:
			set_lpc_anim("IDLE");
		else:
			set_lpc_anim("MOVE", false);
	return movt;

func get_unstunned_movt() -> Vector3:
	return .get_movt_vect();

func _heavy_ready() -> void:
	LPCLeader.adv_anim();
	next_atk_mode = "heavy";

func _on_animWeps_animation_finished(anim: String) -> void:
	if anim == "prepare_right" || anim == "prepare_left":
		_heavy_ready();

func set_lpc_anim(an: String, restart := true) -> void:
	LPCLeader.set_anim_name(an, restart);
	if an == "MOVE" || an == "DEAD":
		if LPCAutoAdv.is_stopped():
			LPCAutoAdv.start();
	else:
		LPCAutoAdv.stop();

func _on_LPCAutoAdvance_timeout():
	LPCLeader.adv_anim();
