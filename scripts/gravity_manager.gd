extends Node

@export var G: float = 100.0
@export var softening: float = 10.0
@export var max_speed: float = 1500.0
@export var substeps: int = 4


func _physics_process(delta: float) -> void:
	var bodies := get_tree().get_nodes_in_group("bodies")
	var dt := delta / substeps
	for i in substeps:
		_step(bodies, dt)


func _step(bodies: Array, dt: float) -> void:
	var accels: Array[Vector2] = []
	accels.resize(bodies.size())
	accels.fill(Vector2.ZERO)

	for i in bodies.size():
		for j in range(i + 1, bodies.size()):
			var a: Body = bodies[i]
			var b: Body = bodies[j]
			var d := b.global_position - a.global_position
			var dist_sq := d.length_squared() + softening * softening
			var dir := d / sqrt(dist_sq)
			accels[i] += dir * G * b.mass / dist_sq
			accels[j] -= dir * G * a.mass / dist_sq
			bodies[i].resolve_overlap(bodies[j])

	for i in bodies.size():
		var body: Body = bodies[i]
		if body.is_static:
			continue
		body.velocity += accels[i] * dt
		body.velocity = body.velocity.limit_length(max_speed)
		body.global_position += body.velocity * dt
