class_name Body
extends Area2D

## The smallest mass a body is allowed to have.
const MIN_MASS := 0.1

## How much mass makes 1 pixel of radius (radius = mass / this).
const MASS_PER_PIXEL_OF_RADIUS := 1000.0

## How many line segments are used to draw the circle outline.
const OUTLINE_SEGMENTS := 48
const OUTLINE_WIDTH := 1.5

## How bouncy collisions are (0 = no bounce, 1 = perfect bounce). Not used yet.
const RESTITUTION := 0.8

## The body's mass. Changing it also resizes the body.
@export var mass: float = 1E5:
	set(new_mass):
		mass = max(new_mass, MIN_MASS)
		update_radius()
		queue_redraw()

## If true, the body never moves, but other bodies still bump into it.
@export var is_static: bool = false

## Magnet-like charge. Neutral bodies always attract with normal gravity.
## Between two charged bodies, opposites attract and equals repel.
enum Polarity { NEGATIVE = -1, NEUTRAL = 0, POSITIVE = 1 }

const POSITIVE_COLOUR := Color.ORANGE_RED
const NEGATIVE_COLOUR := Color.DODGER_BLUE
## Gap between the outline and the polarity ring.
const POLARITY_RING_GAP := 2.0

@export var polarity: Polarity = Polarity.NEUTRAL:
	set(new_polarity):
		polarity = new_polarity
		queue_redraw()


@export var colour: Color = Color.WHITE
@export var initial_velocity: Vector2 = Vector2.ZERO
@export var collider: CollisionShape2D

var radius: float = 1.0
var velocity: Vector2 = Vector2.ZERO

## Pull from all other bodies, set by the GravityManager every step.
var gravity_acceleration: Vector2 = Vector2.ZERO

## Mass per unit of area.
var density: float:
	get:
		return mass / (PI * radius * radius)


func _ready() -> void:
	velocity = initial_velocity
	add_to_group("bodies")
	update_radius()
	print(get_children())  # Debug: lists this body's child nodes


## If this body and `other` overlap, pushes them apart and stops them
## moving further into each other.
func resolve_overlap(other: Body) -> void:

	if is_static and other.is_static:
		return

	var offset_to_other := other.global_position - global_position
	var distance_between_centres := offset_to_other.length()
	var touching_distance := radius + other.radius
	
	if distance_between_centres >= touching_distance:
		return  # Not overlapping

	# Direction from this body to the other one (length 1).
	# If both centres are in exactly the same spot, pick any direction.
	var push_direction := Vector2.RIGHT
	if distance_between_centres > 0.0:
		push_direction = offset_to_other / distance_between_centres

	# "Inverse mass" (1 / mass) decides how much each body moves:
	# heavy bodies get a small value and move less, static bodies get 0 and don't move.
	var my_inverse_mass := 0.0 if is_static else 1.0 / mass
	var other_inverse_mass := 0.0 if other.is_static else 1.0 / other.mass
	var total_inverse_mass := my_inverse_mass + other_inverse_mass

	# Split the overlap between the two bodies, in proportion to their inverse masses.
	var overlap_amount := touching_distance - distance_between_centres
	var my_share := my_inverse_mass / total_inverse_mass
	var other_share := other_inverse_mass / total_inverse_mass
	global_position -= push_direction * overlap_amount * my_share
	other.global_position += push_direction * overlap_amount * other_share

	# If they're still moving toward each other, cancel the part of each velocity
	# that points into the collision. Sideways (sliding) motion is kept.
	var relative_velocity := velocity - other.velocity
	var are_moving_closer := relative_velocity.dot(push_direction) > 0.0
	if are_moving_closer:
		if not is_static:
			velocity -= push_direction * velocity.dot(push_direction)
		if not other.is_static:
			other.velocity -= push_direction * other.velocity.dot(push_direction)


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, OUTLINE_SEGMENTS, colour, OUTLINE_WIDTH)
	if polarity != Polarity.NEUTRAL:
		var ring_colour := POSITIVE_COLOUR if polarity == Polarity.POSITIVE else NEGATIVE_COLOUR
		draw_arc(Vector2.ZERO, radius + POLARITY_RING_GAP, 0.0, TAU, OUTLINE_SEGMENTS, ring_colour, OUTLINE_WIDTH)


## Sets the radius from the mass and resizes the collision circle to match.
func update_radius() -> void:
	radius = mass / MASS_PER_PIXEL_OF_RADIUS
	# The collider isn't ready yet when the mass is first set in the editor.
	if is_node_ready():
		(collider.shape as CircleShape2D).radius = radius