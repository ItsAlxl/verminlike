extends Spatial

const MAX_MOBS := 30;
var all_mobs := [];

func _ready() -> void:
	Game.level = self;

func add_mob(at_transl: Vector3, limit_after := true) -> void:
	var at_cap := all_mobs.size() >= MAX_MOBS;
	
	if at_cap && !limit_after:
		_rem_furthest_mob();
	
	var m := preload("res://unit/Mob.tscn").instance();
	add_child(m);
	m.global_transform.origin = at_transl;
	all_mobs.append(m);
	
	if at_cap && limit_after:
		_rem_furthest_mob();

func rem_mob(m: Mob) -> void:
	all_mobs.erase(m);
	remove_child(m);
	m.queue_free();

func _rem_furthest_mob() -> void:
	var fm: Mob = null;
	var fdsq := 0.0;
	for m in all_mobs:
		if m.dist_sq_to_plr > fdsq:
			fdsq = m.dist_sq_to_plr;
			fm = m;
	rem_mob(fm);
