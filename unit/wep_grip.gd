extends Spatial

func set_hits_active(a: bool) -> void:
	if get_child_count() > 0:
		get_child(0).set_hits_active(a);
