class_name Player
extends Unit

onready var cam_alive: Camera = $Head/Pitch/CameraAlive
onready var cam_dead: Camera = $Head/CameraDead;

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _setup_weps() -> void:
	Game.plr = self;
	HUD.take_ammo_pool(ammo_pool);
	HUD.take_hp(hp_now, hp_max);
	._setup_weps();

func _input(ev: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Look
		if ev is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			var mouse_sensitivity: float = Settings.get_value("look_sensitivity") * 0.0001;
			head.rotate_y(-ev.relative.x * mouse_sensitivity);
			pitch.rotate_x(-ev.relative.y * mouse_sensitivity);
			pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -90, 90);
		
		if is_alive():
			# Movement
			if ev.is_action_pressed("movt_jump"):
				should_jump = true;
			if ev.is_action_released("movt_jump"):
				should_dejump = true;
			if ev.is_action_pressed("dodge"):
				should_dodge = true;
			
			# Weapons
			if is_wep_ranged():
				if ev.is_action_pressed("atk_primary"):
					shoot_ranged();
				if ev.is_action_pressed("reload"):
					reload_ranged();
			else:
				if ev.is_action_pressed("atk_primary"):
					start_melee_attack();
				if ev.is_action_released("atk_primary"):
					release_melee_attack();
			
			if ev.is_action_pressed("block"):
				start_block();
			if ev.is_action_released("block"):
				end_block();
			
			if ev.is_action_pressed("switch_wep"):
				switch_wep();

func die():
	.die();
	cam_dead.current = true;
	$CleanUp.stop();
	HUD.take_final_state("died");

func take_dmg(dmg: float) -> void:
	.take_dmg(dmg);
	HUD.take_hp(hp_now, hp_max);
func reload_ranged() -> void:
	.reload_ranged();
	HUD.take_ammo_pool(ammo_pool);

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
