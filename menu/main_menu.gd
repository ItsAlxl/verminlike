extends Control

onready var RTLCredits := $Main/RTLCredits;

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
	
	HUD.change_vol(Settings.get_value("master_vol"));
	$Main/VBoxMenu/SliderVol.value = Settings.get_value("master_vol");
	$Main/VBoxMenu/LblVol/NUDVol.value = Settings.get_value("master_vol");

func _on_BtnCredits_toggled(t: bool) -> void:
	RTLCredits.visible = t;
	$Main/Logo.visible = !t;

func _on_NUDVol_value_changed(val: float):
	$Main/VBoxMenu/SliderVol.value = val;
	HUD.change_vol(val);

func _on_SliderVol_value_changed(val: float):
	$Main/VBoxMenu/LblVol/NUDVol.value = val;
	HUD.change_vol(val);

func _on_RTLCredits_meta_clicked(meta):
	OS.shell_open(meta);

func _on_BtnPlay_pressed():
	HUD.change_scene("ATG");

func _on_BtnDbg_pressed():
	HUD.change_scene("DBG");

func _on_BtnQuit_pressed():
	get_tree().quit();
