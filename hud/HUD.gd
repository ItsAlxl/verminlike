extends CanvasLayer

func take_readout(readout: String) -> void:
	$Control/Readout.text = readout;

func take_ammo(at: int, of: int) -> void:
	$RevolverAmmo.set_max(of);
	$RevolverAmmo.set_now(at);
