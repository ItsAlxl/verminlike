extends Spatial

export var on_timer := -1;
export var dist_sq_to_plr := 1000.0;
export var spread := Vector2(1, 1);
export var initial := 0;

var enabled := false;
var meets_dist_req := false;
var on_pt := -1;

func _physics_process(_delta: float) -> void:
	var dist_ok := dist_sq_to_plr < 0 || (translation - Game.plr.translation).length_squared() <= dist_sq_to_plr;
	if meets_dist_req != dist_ok:
		meets_dist_req = dist_ok;
		enable(dist_ok);

func spawn() -> void:
	var latest := preload("res://unit/Mob.tscn").instance();
	if get_child_count() > 0:
		on_pt = (on_pt + 1) % get_child_count();
		latest.global_transform = get_child(on_pt).global_transform;
	else:
		latest.global_transform = global_transform;
	latest.translate(Vector3(rand_range(-spread.x, spread.x), 0, rand_range(-spread.y, spread.y)));
	Game.level.add_child(latest);

func enable(en: bool) -> void:
	if en != enabled:
		enabled = false;
		if en:
			for _i in range(initial):
				spawn();
			initial = 0;
			spawn();
			if on_timer > 0:
				enabled = true;
				$SpawnTime.start(on_timer);
		else:
			$SpawnTime.stop();

func _on_SpawnTime_timeout():
	spawn();
