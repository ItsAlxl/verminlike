extends Area

func _ready() -> void:
	collision_layer = get_unit().collision_layer;
	collision_mask = get_unit().collision_layer;

func get_unit() -> Unit:
	return get_parent() as Unit;

func enable(e: bool) -> void:
	for c in get_children():
		if c is CollisionShape:
			c.disabled = !e;
