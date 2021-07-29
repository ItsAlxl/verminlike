class_name Player
extends Unit

onready var camera: Camera = $Head/Pitch/Camera
var mouse_sensitivity := 0.0009;

func _ready() -> void:
	._ready();
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	Game.plr = self;

func _input(ev: InputEvent) -> void:
	# Player look
	if ev is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-ev.relative.x * mouse_sensitivity);
		pitch.rotate_x(-ev.relative.y * mouse_sensitivity);
		pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -90, 90);
	
	# Jump
	if ev.is_action_pressed("movt_jump"):
		should_jump = true;
	if ev.is_action_released("movt_jump"):
		should_dejump = true;
	
	# Attack / block
	if ev.is_action_pressed("atk_primary"):
		start_melee_attack();
	if ev.is_action_released("atk_primary"):
		release_melee_attack();
	
	if ev.is_action_pressed("block"):
		start_block();
	if ev.is_action_released("block"):
		end_block();
	
	# Capture/release mouse
	if ev.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func get_unstunned_movt() -> Vector3:
	var move := Vector3.ZERO;
	move += (Input.get_action_strength("movt_back") - Input.get_action_strength("movt_fwd")) * head.transform.basis.z;
	move += (Input.get_action_strength("movt_right") - Input.get_action_strength("movt_left")) * head.transform.basis.x;
	return move.normalized();
