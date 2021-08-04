extends Node

const IDX_MAP := {
	"CAST": 0,
	"STAB": 4,
	"MOVE": 8,
	"SWIPE": 12,
	"ARCHER": 16,
	"DEAD": 20,
};
const ANIM_LENGTHS := {
	"CAST": 7,
	"STAB": 8,
	"MOVE": 9,
	"SWIPE": 6,
	"ARCHER": 13,
	"DEAD": 5,
};
var current_anim := "";

export var frame_x := 0 setget set_frame_x, get_frame_x;
export var anim_idx := 0 setget set_anim_idx, get_anim_idx;

var facing_dir := 0 setget set_facing_dir;

var _corrected_fliph := false;
var flip_h := false;

func _upd_children_y() -> void:
	var frame_y: int = IDX_MAP.DEAD if anim_idx == IDX_MAP.DEAD else anim_idx + facing_dir;
	
	_corrected_fliph = flip_h;
	if anim_idx == IDX_MAP.SWIPE && facing_dir == 2:
		_corrected_fliph = !_corrected_fliph;
	set_flip_h(_corrected_fliph);
	
	for c in get_children():
		if c is Sprite3D or c is Sprite:
			c.frame_coords.y = frame_y;

func set_frame_x(fx: int) -> void:
	frame_x = fx;
	for c in get_children():
		if c is Sprite3D or c is Sprite:
			c.frame_coords.x = fx;
func get_frame_x() -> int:
	return frame_x;

func set_anim_idx(ar: int) -> void:
	anim_idx = ar;
	_upd_children_y();
func get_anim_idx() -> int:
	return anim_idx;

func set_facing_dir(fd: int) -> void:
	facing_dir = fd;
	_upd_children_y();

func set_flip_h(fh: bool) -> void:
	for c in get_children():
		if c is Sprite3D:
			c.flip_h = fh;

func set_anim_name(an: String, restart := true) -> void:
	if restart || an != current_anim:
		set_frame_x(0);
		match an:
			"IDLE":
				an = "MOVE";
			"MOVE":
				set_frame_x(2);
			"SWIPE":
				set_frame_x(4);
		
		current_anim = an;
		set_anim_idx(IDX_MAP.get(an, 0));

func adv_anim() -> void:
	if !current_anim.empty():
		var anim_length: int = ANIM_LENGTHS[current_anim];
		match current_anim:
			"SWIPE":
				if frame_x > 0 && frame_x < anim_length - 1:
					if frame_x >= 3:
						set_frame_x(frame_x + 1);
					else:
						set_frame_x(frame_x - 1);
			"MOVE":
				set_frame_x((frame_x + 1) % anim_length);
				if frame_x == 0:
					set_frame_x(1);
			"DEAD":
				if frame_x < anim_length - 1:
					set_frame_x(frame_x + 1);

func apex_swipe_anim() -> void:
	set_frame_x(2);

