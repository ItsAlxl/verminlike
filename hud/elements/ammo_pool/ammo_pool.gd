extends Control

func set_num_bullets(b: int) -> void:
	var diff := b - get_child_count();
	if diff > 0:
		for i in range(diff):
			add_child(preload("res://hud/elements/ammo_pool/bullet_icon.tscn").instance());
	else:
		for i in range(-diff):
			remove_child(get_child(get_child_count() - 1));
