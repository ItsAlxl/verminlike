extends Spatial

export(Array, AudioStream) var sounds := [];
export var const_players := 0;
export var max_players := 5;

export var default_pitch_lower := 0.8;
export var default_pitch_upper := 1.2;

export var untether := true;

var players := [];

func _ready() -> void:
	for i in range(const_players):
		_add_player();

func get_available_player() -> AudioStreamPlayer3D:
	for p in players:
		if !p.playing:
			return p;
	if players.size() < max_players:
		return _add_player();
	return players.front();

func _add_player() -> AudioStreamPlayer3D:
	var newest := AudioStreamPlayer3D.new();
	
	if untether:
		Game.level.add_child(newest);
	else:
		add_child(newest);
	players.append(newest);
	
	newest.attenuation_filter_cutoff_hz = 20500;
	newest.connect("finished", self, "_player_done", [newest]);
	return newest;

func _player_done(p: AudioStreamPlayer3D) -> void:
	if players.size() > const_players:
		players.erase(p);
		p.get_parent().remove_child(p);
		p.queue_free();

func play_from(idxs: Array) -> void:
	play(idxs[randi() % idxs.size()]);

func play(idx := -1, pitch := rand_range(default_pitch_lower, default_pitch_upper)) -> void:
	if sounds.size() > 0:
		var p := get_available_player();
		if p != null:
			if idx < 0:
				idx = randi() % sounds.size();
			
			if untether:
				p.global_transform = global_transform;
			p.stream = sounds[idx];
			p.pitch_scale = pitch;
			p.play();
