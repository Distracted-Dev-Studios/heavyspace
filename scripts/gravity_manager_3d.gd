extends Node

@export var G: float = 100.0
@export var softening: float = 1.0
@export var max_speed: float = 1500.0
@export var substeps: int = 4


func _physics_process(delta: float) -> void:
	var bodies := get_tree().get_nodes_in_group("bodies")
	var dt := delta / substeps
	for i in substeps:
		_step(bodies, dt)


func _step(bodies: Array, dt: float) -> void:
	var accels: Array[Vector3] = []
	accels.resize(bodies.size())
	accels.fill(Vector3.ZERO)
	var best_pull: Array[float] = []
	best_pull.resize(bodies.size())
	best_pull.fill(0.0)
	var best_parent: Array = []
	best_parent.resize(bodies.size())

	for i in bodies.size():
		for j in range(i + 1, bodies.size()):
			var a: Body3D = bodies[i]
			var b: Body3D = bodies[j]
			var d := b.global_position - a.global_position
			var dist_sq := d.length_squared() + softening * softening
			var dir := d / sqrt(dist_sq)

			var pull_on_a := G * b.mass / dist_sq
			var pull_on_b := G * a.mass / dist_sq

			if pull_on_a > best_pull[i]:
				best_pull[i] = pull_on_a
				best_parent[i] = b
			if pull_on_b > best_pull[j]:
				best_pull[j] = pull_on_b
				best_parent[j] = a

			accels[i] += dir * pull_on_a
			accels[j] -= dir * pull_on_b

			a.resolve_overlap(b)

	for i in bodies.size():
		var body: Body3D = bodies[i]
		body.gravity_acceleration = accels[i]
		if body.is_static:
			continue

		if body.is_orbit_locked:
			# Keep the parent chosen at lock time; only pick one if none is set
			if body.orbit_parent == null:
				body.orbit_parent = best_parent[i]
			if body.orbit_parent:
				_step_locked(body, dt)
				continue

		body.velocity += accels[i] * dt
		body.velocity = body.velocity.limit_length(max_speed)
		body.global_position += body.velocity * dt


func _step_locked(body: Body3D, dt: float) -> void:
	var parent := body.orbit_parent
	var offset := body.global_position - parent.global_position
	var r := offset.length()
	if r < 0.001:
		return

	var rel_vel := body.velocity - parent.velocity
	var speed := rel_vel.length() # preserved
	if speed < 0.001:
		# Nothing to orbit with; just match the parent.
		body.velocity = parent.velocity
		return

	# The orbit plane's normal. The sign of this axis keeps the spin direction.
	var axis := offset.cross(rel_vel)
	if axis.length_squared() < 0.000001:
		# Velocity is purely radial, so the plane is undefined. Pick any
		# axis perpendicular to the offset.
		var helper := Vector3.UP if absf(offset.normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		axis = offset.cross(helper)
	axis = axis.normalized()

	# Rotate around the parent by the arc length travelled this step
	var new_offset := offset.rotated(axis, speed * dt / r)
	var tangent := axis.cross(new_offset).normalized()

	body.global_position = parent.global_position + new_offset
	body.velocity = parent.velocity + tangent * speed
