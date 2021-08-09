extends Sprite

var ammo_max := -1 setget set_max, get_max;
var ammo_now := -1 setget set_now, get_now;

func _upd_filled() -> void:
	for i in range(get_child_count()):
		get_child(i).filled = i < ammo_now;

func set_max(m: int) -> void:
	var old_max := ammo_max;
	ammo_max = int(max(1, m));
	if ammo_max != old_max:
		for c in get_children():
			remove_child(c);
			c.queue_free();
		
		var rot_step := 2 * PI / m;
		for i in range(ammo_max):
			var slot := preload("res://hud/elements/revolver_ammo/revolver_ammo_slot.tscn").instance();
			add_child(slot);
			slot.rotation = rot_step * i;

func get_max() -> int:
	return ammo_max;

func set_now(n: int) -> void:
	var old_now := ammo_now;
	ammo_now = int(clamp(n, 0, ammo_max));
	if ammo_now != old_now:
		_upd_filled();

func get_now() -> int:
	return ammo_now;
