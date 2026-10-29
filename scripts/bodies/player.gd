class_name Player
extends Body

@export var thrust_force: float = 2E5
@export var mass_rate: float = 5E4


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var thrust_velocity = input * (thrust_force / mass) * delta
	print(thrust_velocity)
	velocity += thrust_velocity

	if Input.is_physical_key_pressed(KEY_E):
		mass = mass + mass_rate * delta
	if Input.is_physical_key_pressed(KEY_Q):
		mass = mass - mass_rate * delta
