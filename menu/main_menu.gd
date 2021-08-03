extends Control

const MIN_DB = -45.0;
const MAX_DB = 5.0;

onready var RTLCredits := $RTLCredits;

func _ready():
	HUD.enable(false);
	RTLCredits.push_align(RichTextLabel.ALIGN_CENTER);
	RTLCredits.add_text("alxl made this");
	RTLCredits.newline();
	RTLCredits.add_text("Released under MIT License");
	RTLCredits.newline();
	RTLCredits.add_text("Copyright (c) 2021 alxl");
	RTLCredits.newline();
	RTLCredits.newline();
	RTLCredits.newline();
	var f := File.new();
	f.open("res://THIRD_PARTY_LICENSES", File.READ);
	while !f.eof_reached():
		RTLCredits.newline();
		RTLCredits.append_bbcode(f.get_line().replace("<", "<[url]").replace(">", "[/url]>"));
	RTLCredits.pop();
	f.close();
	set_db_perc(Settings.get_value("master_vol"));

func _on_BtnCredits_toggled(t: bool) -> void:
	RTLCredits.visible = t;
	$Logo.visible = !t;

func _on_NUDVol_value_changed(val: float):
	set_db_perc(val);

func _on_SliderVol_value_changed(val: float):
	set_db_perc(val);

func set_db_perc(perc: float) -> void:
	$VBoxMenu/LblVol/NUDVol.value = perc;
	$VBoxMenu/SliderVol.value = perc;
	Settings.set_value("master_vol", perc);
	
	var db := -200;
	if perc > 0.0:
		db = lerp(MIN_DB, MAX_DB, perc * 0.01);
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db);


func _on_RTLCredits_meta_clicked(meta):
	OS.shell_open(meta);

func _on_BtnPlay_pressed():
	HUD.change_scene("ATG");

func _on_BtnDbg_pressed():
	HUD.change_scene("DBG");

func _on_BtnQuit_pressed():
	get_tree().quit();
