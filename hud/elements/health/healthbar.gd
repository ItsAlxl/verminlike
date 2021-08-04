extends Control

const HP_INVERSE_CLR_GRADIENT := preload("res://hud/elements/health/gradient_health.tres");

func set_hp(at: float, of: float) -> void:
	$Progress.max_value = of;
	$Progress.value = at;
	$Progress.tint_progress = HP_INVERSE_CLR_GRADIENT.interpolate(at / of).inverted();
