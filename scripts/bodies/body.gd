class_name Body
extends Area2D

@export var mass: float = 1E5:
	set(value):
		mass = max(value, 0.1)
		update_radius()
		queue_redraw()
@export var is_static: bool = false
@export var colour: Color = Color.WHITE
@export var initial_velocity: Vector2 = Vector2.ZERO
@export var collider: CollisionShape2D

const RESTITUTION := 0.8

var radius: float = 1.0
var velocity: Vector2 = Vector2.ZERO
var density: float:
	get:
		return mass / (PI * radius * radius)


func _ready() -> void:
	velocity = initial_velocity
	add_to_group("bodies")
	update_radius()
	print(get_children())


func resolve_overlap(other: Body) -> void:
	if is_static and other.is_static:
		return

	var d := other.global_position - global_position
	var dist := d.length()
	var min_dist := radius + other.radius
	if dist >= min_dist:
		return

	# Exactly overlapping: pick an arbitrary direction
	var n := d / dist if dist > 0.0 else Vector2.RIGHT

	# Push apart. Heavier bodies move less, static bodies don't move.
	var inv_a := 0.0 if is_static else 1.0 / mass
	var inv_b := 0.0 if other.is_static else 1.0 / other.mass
	var inv_sum := inv_a + inv_b
	var overlap := min_dist - dist
	global_position -= n * overlap * inv_a / inv_sum
	other.global_position += n * overlap * inv_b / inv_sum

	# Stop them pushing into each other, but keep sideways (sliding) motion
	if (velocity - other.velocity).dot(n) > 0.0:
		if not is_static:
			velocity -= n * velocity.dot(n)
		if not other.is_static:
			other.velocity -= n * other.velocity.dot(n)


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, colour, 1.5)


func update_radius():
	radius = mass / 1000
	if is_node_ready():
		(collider.shape as CircleShape2D).radius = radius
