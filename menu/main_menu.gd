extends Control

onready var RTLCredits := $Main/RTLCredits;

func _ready():
	HUD.enable(false);
	RTLCredits.push_align(RichTextLabel.ALIGN_CENTER);
	RTLCredits.add_text("Beat and Chaff");
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
	$Equip/LPCLeader.set_anim_name("MOVE");
	
	for i in range(Game.LPC_ORDER.size()):
		var cat = Game.LPC_ORDER[Game.LPC_ORDER.size() - 1 - i];
		var lbl := Label.new();
		lbl.text = cat.capitalize();
		
		var sel_opt: String = Settings.get_value("lpc_opts").get(cat, "none");
		var combox := OptionButton.new();
		combox.name = cat;
		for opt in Game.get_lpc_options(cat):
			combox.add_item(opt.capitalize());
			if sel_opt == opt:
				combox.select(combox.get_item_count() - 1);
				_upd_lpc_opt(cat, opt);
		combox.connect("item_selected", self, "_lpc_combox_selected", [combox]);
		
		$Equip/Scroll/VBoxLPCOpts.add_child(HSeparator.new());
		$Equip/Scroll/VBoxLPCOpts.add_child(lbl);
		$Equip/Scroll/VBoxLPCOpts.add_child(combox);
	$Equip/Scroll/VBoxLPCOpts.add_child(HSeparator.new());
	_select_combox_from_id($Equip/VBoxWep/ComboxWep, Settings.get_value("mwep"));
	
	show_equip_screen(false);

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
	show_equip_screen(true);

func _on_BtnDbg_pressed():
	_bake_equip();
	HUD.change_scene("DBG");

func _on_BtnQuit_pressed():
	Game.quit();

func _on_BtnGo_pressed():
	_bake_equip();
	HUD.change_scene("ATG");

func _on_BtnBack_pressed():
	show_equip_screen(false);

func show_equip_screen(s: bool) -> void:
	$Equip.visible = s;
	$Main.visible = !s;
	if s:
		$Equip/LPCAutoRotate.start();
		$Equip/LPCAutoAdvance.start();
		$Equip/LPCLeader.set_facing_dir(2);
	else:
		$Equip/LPCAutoAdvance.stop();
		$Equip/LPCAutoRotate.stop();

func _on_LPCAutoAdvance_timeout():
	$Equip/LPCLeader.adv_anim();

func _on_LPCAutoRotate_timeout():
	$Equip/LPCLeader.set_facing_dir(($Equip/LPCLeader.facing_dir + 1) % 4);

func _text_to_id(text: String) -> String:
	return text.to_lower().replace(" ", "_");

func _lpc_combox_selected(idx: int, combox: OptionButton) -> void:
	_upd_lpc_opt(combox.name, _text_to_id(combox.get_item_text(idx)));
func _upd_lpc_opt(category: String, option: String) -> void:
	$Equip/LPCLeader.get_node(category).texture = Game.get_lpc_tex(category, option);

func _bake_equip() -> void:
	var opts := {};
	for c in $Equip/Scroll/VBoxLPCOpts.get_children():
		if c is OptionButton:
			opts[c.name] = _text_to_id(c.text);
	Settings.set_value("lpc_opts", opts);
	Settings.set_value("mwep", _text_to_id($Equip/VBoxWep/ComboxWep.text));

func _select_combox_from_id(combox: OptionButton, id: String) -> void:
	var text := id.capitalize();
	for i in range(combox.get_item_count()):
		if text == combox.get_item_text(i):
			combox.select(i);
			return;
