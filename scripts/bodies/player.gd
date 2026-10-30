class_name Player
extends Body

## Size of the direction triangles drawn around the player.
const ARROW_SIZE := 10.0
## Gap between the player's outline and the triangles.
const ARROW_GAP := 4.0
const INPUT_ARROW_COLOUR := Color.GREEN
const GRAVITY_ARROW_COLOUR := Color.CYAN
const TRAIL_COLOR = Color8(255, 0, 0, 50)
const MAX_TRAIL_POINTS = 250

@export var thrust_force: float = 2E5
@export var mass_rate: float = 5E4

var trail: Array[Vector2] = []


func _process(_delta: float):
	trail.append(global_position)
	if trail.size() > MAX_TRAIL_POINTS:
		trail.pop_front()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_E):
		mass = mass + mass_rate * delta
	if Input.is_physical_key_pressed(KEY_Q):
		mass = mass - mass_rate * delta
	if Input.is_action_just_pressed("toggle_orbit_lock"):
		is_orbit_locked = !is_orbit_locked

	queue_redraw()


func _draw() -> void:
	super()
	_draw_arrow(gravity_acceleration, GRAVITY_ARROW_COLOUR)
	_draw_trail_point()


func _draw_arrow(direction: Vector2, arrow_colour: Color) -> void:
	if direction.is_zero_approx():
		return
	var forward := direction.normalized()
	var side := forward.orthogonal() * ARROW_SIZE * 0.5
	var base := forward * (radius + ARROW_GAP)
	var tip := base + forward * ARROW_SIZE
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), arrow_colour)


func _draw_trail_point():
	for p in trail:
		draw_circle(to_local(p), 2.0, TRAIL_COLOR)
