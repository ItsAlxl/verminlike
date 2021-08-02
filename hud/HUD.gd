extends CanvasLayer

func enable(e: bool) -> void:
	$InGameHUD.visible = e;

func take_ammo(at: int, of: int) -> void:
	$InGameHUD/RevolverAmmo.set_max(of);
	$InGameHUD/RevolverAmmo.set_now(at);
