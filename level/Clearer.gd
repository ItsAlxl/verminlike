extends Spatial

export var dist_sq_to_plr := 500.0;

func _physics_process(_delta: float) -> void:
	if (translation - Game.plr.translation).length_squared() <= dist_sq_to_plr:
		Game.level.clear_all_mobs();
		queue_free();
