extends Node2D

@onready var player: Player = $Player
@onready var label: Label = $HUD/Label


func _process(_delta: float) -> void:
	label.text = "Density: %.1f\nMass: %.1f\nSpeed: %.0f\nPolarity: %s\nQ/E: density  Arrows: thrust  F: flip polarity  R: restart" % [
		player.density,
		player.mass,
		player.velocity.length(),
		"+" if player.polarity == Body.Polarity.POSITIVE else "-",
	]
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene()
