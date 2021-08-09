extends Spatial

export var on_timer := -1;
export var spawn_per_timer := 1.0;
export var dist_sq_to_plr := 500.0;
export var spread := Vector2(0.5, 0.5);
export var initial := 0;
export var start_aggro := false;

var enabled := false;
var met_dist_req := false;
var on_pt := -1;

func _physics_process(_delta: float) -> void:
	if !met_dist_req:
		met_dist_req = dist_sq_to_plr < 0 || (translation - Game.plr.translation).length_squared() <= dist_sq_to_plr;
		if met_dist_req:
			enable(true);
	elif initial > 0:
		spawn();
		initial -= 1;

func spawn(limit_after := false) -> void:
	var place := Vector3(rand_range(-spread.x, spread.x), 0, rand_range(-spread.y, spread.y));
	if get_child_count() > 0:
		on_pt = (on_pt + 1) % get_child_count();
		while !("global_transform" in get_child(on_pt)):
			on_pt = (on_pt + 1) % get_child_count();
		place += get_child(on_pt).global_transform.origin;
	else:
		place += global_transform.origin;
	
	Game.level.add_mob(place, limit_after, start_aggro);

func enable(en: bool) -> void:
	if en != enabled:
		enabled = false;
		if en:
			if on_timer > 0:
				enabled = true;
				$SpawnTime.start(on_timer);
		else:
			$SpawnTime.stop();

func _on_SpawnTime_timeout():
	for i in range(spawn_per_timer):
		spawn(false);
