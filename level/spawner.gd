extends Spatial

export var on_timer := -1;

func _ready() -> void:
	if on_timer > 0:
		$SpawnTime.start(on_timer);

func spawn() -> void:
	var latest := preload("res://unit/Mob.tscn").instance();
	latest.global_transform = global_transform;
	Game.level.add_child(latest);

func _on_SpawnTime_timeout():
	spawn();
