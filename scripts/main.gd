extends Node2D

@onready var player: Player = $Player
@onready var label: Label = $HUD/Label


func _process(_delta: float) -> void:
	label.text = "Density: %.1f\nMass: %.1f\nSpeed: %.0f\nQ/E: density  Arrows: thrust  R: restart" % [
		player.density,
		player.mass,
		player.velocity.length(),
	]
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene()
