class_name Player
extends Body

## Size of the direction triangles drawn around the player.
const ARROW_SIZE := 10.0
## Gap between the player's outline and the triangles.
const ARROW_GAP := 4.0
const INPUT_ARROW_COLOUR := Color.GREEN
const GRAVITY_ARROW_COLOUR := Color.CYAN

@export var thrust_force: float = 2E5
@export var mass_rate: float = 5E4

var input_direction: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var thrust_velocity = input_direction * (thrust_force / mass) * delta
	print(thrust_velocity)
	velocity += thrust_velocity

	if Input.is_physical_key_pressed(KEY_E):
		mass = mass + mass_rate * delta
	if Input.is_physical_key_pressed(KEY_Q):
		mass = mass - mass_rate * delta

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# F flips the player's polarity between positive and negative.
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		polarity = Polarity.NEGATIVE if polarity == Polarity.POSITIVE else Polarity.POSITIVE


func _draw() -> void:
	super()
	_draw_arrow(input_direction, INPUT_ARROW_COLOUR)
	_draw_arrow(gravity_acceleration, GRAVITY_ARROW_COLOUR)


## Draws a triangle just outside the outline, pointing in `direction`.
func _draw_arrow(direction: Vector2, arrow_colour: Color) -> void:
	if direction.is_zero_approx():
		return
	var forward := direction.normalized()
	var side := forward.orthogonal() * ARROW_SIZE * 0.5
	var base := forward * (radius + ARROW_GAP)
	var tip := base + forward * ARROW_SIZE
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), arrow_colour)
