tool
extends Spatial

# References to other scenes
const MapChunk = preload("res://Map/MapChunk.tscn")

# Map generation parameters
export var radius : int = 15;
export var minheight : float = 0.5
export var maxheightc : float = 28.0
export var gradient : float = 0.25
export var octaves : int = 4
export var period : float = 20.0
export var persistance : float = 0.1

# Movement parameters
export var max_fallheight : float = 10.0
export var max_climbheight : float = 5.0

# Map array
var maparr = []
var id2chunk = {}
var id_count = 0
var astarmap : AStar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	astarmap = AStar.new()
	_initial_mapgen()
	_generate_navmesh()

func _regen_map() -> void:
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance
	
	for x in range(-radius, radius+1):
		for z in range(-radius, radius+1):
			_regen_chunk(x, z, noise.get_noise_2d(x, z))
	_generate_navmesh()

func _initial_mapgen() -> void:
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance
	
	maparr.resize((radius+1) * 2)
	for x in range(len(maparr)):
		maparr[x] = []
		maparr[x].resize((radius+1) * 2)
	for x in range(-radius, radius+1):
		for z in range(-radius, radius+1):
			_gen_chunk(x, z, noise.get_noise_2d(x, z))

func _generate_navmesh() -> void:
	astarmap.clear()
	for x in range(-radius, radius+1):
		for z in range(-radius, radius+1):
			var curnode = get_chunk(x, z)
			if !is_instance_valid(curnode):
				continue
			astarmap.add_point(curnode.id, curnode.get_platform_pos())
	for x in range(-radius, radius+1):
		for z in range(-radius, radius+1):
			var curnode = get_chunk(x, z)
			if !is_instance_valid(curnode):
				continue
			var neighbors = get_neighbor_chunks(x, z)
			for n in neighbors:
				_handle_navmesh_connection(curnode, n)

func _handle_navmesh_connection(from, to) -> void:
	var heightdiff = to.plat_height - from.plat_height
	if (heightdiff < max_climbheight) && (heightdiff > -max_fallheight):
		astarmap.connect_points(from.id, to.id, false)

func get_neighbor_chunks(x: int, z: int):
	var rval = []
	for xi in [1, -1]:
		var zi = 0
		var curnode = get_chunk(x + xi, z + zi)
		if is_instance_valid(curnode):
			rval.append(curnode)
	for zi in [1, -1]:
		var xi = 0
		var curnode = get_chunk(x + xi, z + zi)
		if is_instance_valid(curnode):
			rval.append(curnode)
	return rval

func get_chunk(x : int, z : int):
	x = x + radius
	z = z + radius
	if x < 0 or z < 0 or x >= len(maparr) or z >= len(maparr[x]):
		return null
	return maparr[x][z]

func _gen_chunk(x : int, z : int, displaceval) -> void:
	var dist = sqrt(x*x + z*z)
	if dist > radius:
		return
	var mc = MapChunk.instance()
	mc.height = pow(2, (maxheightc - dist) * gradient) + minheight
	maparr[x + radius][z + radius] = mc
	mc.translation = Vector3(x * mc.width, 0, z * mc.width)
	add_child(mc)
	mc.set_displacement(displaceval)
	mc.id = id_count
	id2chunk[id_count] = mc
	id_count += 1

func _regen_chunk(x : int, z : int, displaceval) -> void:
	var mc = get_chunk(x, z)
	if is_instance_valid(mc):
		mc.set_displacement(displaceval)

var othernode = null
var prevselected = null
func _physics_process(delta: float) -> void:
	while len(Global.unhandled_input_queue) > 0:
		var event = Global.unhandled_input_queue.pop_front()
		# TODO: Handle input
		if (event is InputEventMouseButton) and (event.button_index == BUTTON_LEFT) and (!event.pressed):
			var scenery = $Camera.get_scenery_at_point(event.position)
			if is_instance_valid(scenery):
				if !is_instance_valid(othernode):
					othernode = scenery
				else:
					print(astarmap.get_point_connections(othernode.id))
					var pp = astarmap.get_id_path(othernode.id, scenery.id)
					var list = []
					for id in pp:
						list.append(id2chunk[id].get_platform_pos() + Vector3(0, 1, 0))
					$LineRenderer.points = list
					othernode = null
		if (event is InputEventMouseMotion):
			if is_instance_valid(prevselected):
				prevselected.set_selected(false)
			prevselected = $Camera.get_scenery_at_point(event.position)
			if is_instance_valid(prevselected):
				prevselected.set_selected(true)
