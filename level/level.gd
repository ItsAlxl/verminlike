extends Spatial

const MAX_MOBS := 30;
var all_mobs := [];

func _ready() -> void:
	Game.level = self;
	HUD.enable(true);

func add_mob(at_transl: Vector3, limit_after := true, aggro := false) -> void:
	var at_cap := all_mobs.size() >= MAX_MOBS;
	
	if at_cap && !limit_after:
		_rem_furthest_mob();
	
	var m := preload("res://unit/Mob.tscn").instance();
	add_child(m);
	m.global_transform.origin = at_transl;
	all_mobs.append(m);
	if aggro:
		m.spread_aggro();
	
	if at_cap && limit_after:
		_rem_furthest_mob();

func rem_mob(m: Mob) -> void:
	all_mobs.erase(m);
	m.sleeping = true;
	m.queue_free();

func _rem_furthest_mob() -> void:
	var fm: Mob = null;
	var fdsq := 0.0;
	for m in all_mobs:
		if m.is_dead:
			fm = m;
			break;
		if m.dist_sq_to_plr > fdsq:
			fdsq = m.dist_sq_to_plr;
			fm = m;
	rem_mob(fm);

func clear_all_mobs() -> void:
	for m in all_mobs.duplicate():
		rem_mob(m);

func _on_EndArea_body_entered(body: PhysicsBody) -> void:
	if body == Game.plr:
		$EndLvlTimer.start();
		HUD.take_final_state("won");

func _on_EndLvlTimer_timeout():
	HUD.change_scene("menu");
