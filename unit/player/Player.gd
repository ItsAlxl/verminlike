class_name Player
extends Unit

onready var cam_alive: Camera = $Head/Pitch/CameraAlive
onready var cam_dead: Camera = $Head/CameraDead;
var mouse_sensitivity: float = Settings.get_data("mouse_sensitivity");

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

func die():
	.die();
	cam_dead.current = true;

func _process(delta: float) -> void:
	if is_dead:
		cam_dead.translate(Vector3(0, 0, 1) * delta);
		if cam_dead.fov > 1:
			cam_dead.fov = max(1.0, cam_dead.fov - 3 * delta);

func _get_facing_2D() -> Vector2:
	if is_dead:
		return Vector2(0, 1).rotated(-head.rotation.y);
	return ._get_facing_2D();

func get_unstunned_movt() -> Vector3:
	return vector2_to_facing(Vector2(
		Input.get_action_strength("movt_right") - Input.get_action_strength("movt_left"),
		Input.get_action_strength("movt_back") - Input.get_action_strength("movt_fwd")
	)).normalized();
