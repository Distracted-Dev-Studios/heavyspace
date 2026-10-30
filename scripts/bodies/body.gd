class_name Body
extends Area2D

const MIN_MASS := 8000
const MASS_PER_PIXEL_OF_RADIUS := 1000.0
const OUTLINE_SEGMENTS := 48
const OUTLINE_WIDTH := 1.5
const RESTITUTION := 0.8
const POSITIVE_COLOUR := Color.ORANGE_RED
const NEGATIVE_COLOUR := Color.DODGER_BLUE

@export var mass: float = 1E5:
	set(new_mass):
		var old_mass: float = mass
		mass = max(new_mass, MIN_MASS)
		conserve_momentum(old_mass, mass)
		update_radius()
		queue_redraw()
@export var is_static: bool = false
@export var colour: Color = Color.WHITE
@export var initial_velocity: Vector2 = Vector2.ZERO
@export var collider: CollisionShape2D
@export var is_orbit_locked: bool = false:
	set(value):
		is_orbit_locked = value
		if not value:
			orbit_parent = null

var radius: float = 1.0
var velocity: Vector2 = Vector2.ZERO
var gravity_acceleration: Vector2 = Vector2.ZERO
var orbit_parent: Body


func _ready() -> void:
	velocity = initial_velocity
	add_to_group("bodies")
	update_radius()


func resolve_overlap(other: Body) -> void:
	if is_static and other.is_static:
		return

	var offset_to_other := other.global_position - global_position
	var distance_between_centres := offset_to_other.length()
	var touching_distance := radius + other.radius

	if distance_between_centres >= touching_distance:
		return

	var push_direction := Vector2.RIGHT
	if distance_between_centres > 0.0:
		push_direction = offset_to_other / distance_between_centres

	var my_inverse_mass := 0.0 if is_static else 1.0 / mass
	var other_inverse_mass := 0.0 if other.is_static else 1.0 / other.mass
	var total_inverse_mass := my_inverse_mass + other_inverse_mass

	var overlap_amount := touching_distance - distance_between_centres
	var my_share := my_inverse_mass / total_inverse_mass
	var other_share := other_inverse_mass / total_inverse_mass
	global_position -= push_direction * overlap_amount * my_share
	other.global_position += push_direction * overlap_amount * other_share

	var relative_velocity := velocity - other.velocity
	var are_moving_closer := relative_velocity.dot(push_direction) > 0.0
	if are_moving_closer:
		if not is_static:
			velocity -= push_direction * velocity.dot(push_direction)
		if not other.is_static:
			other.velocity -= push_direction * other.velocity.dot(push_direction)


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, OUTLINE_SEGMENTS, colour, OUTLINE_WIDTH)


func update_radius() -> void:
	radius = mass / MASS_PER_PIXEL_OF_RADIUS
	if is_node_ready():
		(collider.shape as CircleShape2D).radius = radius


func conserve_momentum(old_mass: float, new_mass: float) -> void:
	velocity = old_mass / new_mass * velocity
