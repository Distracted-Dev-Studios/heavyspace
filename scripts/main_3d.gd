extends Node3D

@onready var player: Player3D = $Player3D
@onready var label: Label = $HUD/Label


func _process(_delta: float) -> void:
	label.text = "Mass: %.1f\nRadius: %.1f\nSpeed: %.0f\nOrbit Locked?: %s\nQ/E: Size\nF: Lock Orbit\nR: restart" % [
		player.mass,
		player.radius,
		player.velocity.length(),
		"True" if player.is_orbit_locked else "False",
	]
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene()
