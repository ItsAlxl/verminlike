tool
extends Sprite

export var filled := false setget set_filled, get_filled;

func set_filled(f: bool) -> void:
	$Bullet.visible = f;
	filled = f;

func get_filled() -> bool:
	return filled;
