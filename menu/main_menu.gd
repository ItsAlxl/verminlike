extends Control

onready var RTLCredits := $RTLCredits;

func _ready():
	RTLCredits.push_align(RichTextLabel.ALIGN_CENTER);
	RTLCredits.add_text("a game by alxl");
	RTLCredits.newline();
	RTLCredits.newline();
	RTLCredits.newline();
	var f := File.new();
	f.open("res://THIRD_PARTY_LICENSES", File.READ);
	while !f.eof_reached():
		RTLCredits.newline();
		RTLCredits.append_bbcode(f.get_line());
	RTLCredits.pop();
	f.close();


func _on_BtnCredits_toggled(t: bool) -> void:
	RTLCredits.visible = t;
