class_name BodyGenerator
extends Node3D

@export var player: Player3D
@export var body_scene: PackedScene

@export_group("Cell")
@export var cell_size: int = 400

@export_group("Generation")
@export var n_generation_radius_in_cells: int = 5
@export var body_spawn_chance: float = 0.05
@export var body_mass_scaling: float = 200000

var rng := RandomNumberGenerator.new()
var max_cells = (n_generation_radius_in_cells * 2) ** 3
var shell_offsets: Array[Vector3i]


class Cell:
	var is_checked: bool = false
	var body: Body3D = null


var cells: Dictionary[Vector3i, Cell] = { }
# body_cells acts like a set in Python
var body_cells: Dictionary[Vector3i, bool]
var player_position: Vector3
var player_cell_position: Vector3i


func _ready() -> void:
	if player == null:
		push_error("BodySpawner: 'player' is not assigned.")
	if body_scene == null:
		push_error("BodySpawner: 'body_scene' is not assigned.")
	shell_offsets = _get_shell_offsets(n_generation_radius_in_cells)
	_generate_bodies()


func _process(_delta: float) -> void:
	if player == null or body_scene == null:
		return
	player_position = player.global_position
	player_cell_position = _position_to_cell(player_position)
	_check_new_cells()
	_clear_stale_cells()


func _generate_bodies() -> void:
	for cell_x_index in range(n_generation_radius_in_cells):
		for cell_y_index in range(n_generation_radius_in_cells):
			for cell_z_index in range(n_generation_radius_in_cells):
				var cell_position := Vector3i(cell_x_index, cell_y_index, cell_z_index)
				cells[cell_position] = Cell.new()
				cells[cell_position].is_checked = true
				if rng.randf() < body_spawn_chance:
					_generate_body(cell_position)


func _generate_body(cell_position: Vector3i) -> void:
	var body := body_scene.instantiate() as Body3D
	cells[cell_position].body = body
	body.position = _cell_to_position(cell_position)
	body.mass = rng.randf() * body_mass_scaling
	body.is_static = true
	add_child(body)
	body_cells[cell_position] = true


func _check_new_cells() -> void:
	for offset in shell_offsets:
		_check_cell(player_cell_position + offset)


func _check_cell(cell_position: Vector3i) -> void:
	if not cells.has(cell_position):
		cells[cell_position] = Cell.new()
	var cell := cells[cell_position]
	if cell.is_checked:
		return
	cell.is_checked = true
	if rng.randf() < body_spawn_chance:
		_generate_body(cell_position)


func _clear_stale_cells() -> void:
	var limit: int = n_generation_radius_in_cells
	for cell_position in body_cells.keys():
		var d: Vector3i = cell_position - player_cell_position
		if maxi(maxi(absi(d.x), absi(d.y)), absi(d.z)) > limit:
			var cell := cells[cell_position]
			cell.body.queue_free()
			cell.body = null
			body_cells.erase(cell_position)
			cells.erase(cell_position)


func _get_shell_offsets(r: int) -> Array[Vector3i]:
	var offsets: Array[Vector3i] = []
	for a in range(-r, r + 1):
		for b in range(-r, r + 1):
			# x faces (full y/z range)
			offsets.append(Vector3i(r, a, b))
			offsets.append(Vector3i(-r, a, b))
	for a in range(-r + 1, r):
		for b in range(-r, r + 1):
			# y faces (x trimmed so edges aren't duplicated)
			offsets.append(Vector3i(a, r, b))
			offsets.append(Vector3i(a, -r, b))
	for a in range(-r + 1, r):
		for b in range(-r + 1, r):
			# z faces (x and y trimmed)
			offsets.append(Vector3i(a, b, r))
			offsets.append(Vector3i(a, b, -r))
	return offsets


func _position_to_cell(input_position: Vector3) -> Vector3i:
	return Vector3i(floor(input_position / cell_size))


func _cell_to_position(cell_position: Vector3i) -> Vector3:
	return cell_position * cell_size
