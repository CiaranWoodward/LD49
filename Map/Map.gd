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
var mapset = []
var mapedgeset = []
var id_count = 0
var astarmap : AStar

var annotationMaterial : SpatialMaterial = preload("res://Map/AnnotationMaterial.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	astarmap = AStar.new()
	_initial_mapgen()
	_generate_navmesh()
	Global.map = self
	_reset_annotation_color()

func _set_crystal():
	var heightmax = 0
	for xi in [-1, 0, 1]:
		for zi in [-1, 0, 1]:
			heightmax = max(get_chunk(xi, zi).plat_height, heightmax)
	for xi in [-1, 0, 1]:
		for zi in [-1, 0, 1]:
			get_chunk(xi, zi).set_exact_displacement(heightmax)
	$Crystal.map_chunk = get_chunk(0, 0)
	get_chunk(0, 0).occupant = $Crystal

func get_unoccupied_crystal_space():
	var possibles = []
	for xi in [-1, 0, 1]:
		for zi in [-1, 0, 1]:
			var mc = get_chunk(xi, zi)
			if is_instance_valid(mc) and !mc.is_occupied():
				possibles.push_back(mc)
	if len(possibles) == 0:
		return null
	return possibles[randi() % len(possibles)]

func _regen_map() -> void:
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance
	
	for x in range(-radius, radius+1):
		for z in range(-radius, radius+1):
			_regen_chunk(x, z, noise.get_noise_2d(x, z))
	_set_crystal()
	_generate_navmesh()
	$Tween.interpolate_callback(self, 1.5, "_regen_done")
	$Tween.start()

func _regen_done():
	Global.regen_done()

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
	_set_crystal()
	$Tween.interpolate_callback(self, 1.5, "_regen_done")
	$Tween.start()

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

func _get_heightdiff(from, to) -> float:
	return to.plat_height - from.plat_height

func _is_heightdiff_movable(from, to) -> bool:
	var heightdiff = _get_heightdiff(from, to)
	return ((heightdiff < max_climbheight) && (heightdiff > -max_fallheight))

func _handle_navmesh_connection(from, to) -> void:
	if _is_heightdiff_movable(from, to):
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

func get_random_chunk():
	var i = randi() % len(mapset)
	return mapset[i]

func _get_random_edge_chunk():
	var i = randi() % len(mapedgeset)
	return mapedgeset[i]

func get_random_edge_chunk(allow_occupied : bool = false):
	var retval = _get_random_edge_chunk()
	while (!allow_occupied) && retval.is_occupied():
		retval = _get_random_edge_chunk()
	return retval

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
	mc.x = x
	mc.z = z
	if dist > (radius - 1):
		mapedgeset.append(mc)
	id2chunk[id_count] = mc
	mapset.append(mc)
	id_count += 1

func _regen_chunk(x : int, z : int, displaceval) -> void:
	var mc = get_chunk(x, z)
	if is_instance_valid(mc):
		mc.set_displacement(displaceval)

var prevfrom = null
var prevto = null
var prevresult = []
# get a meshchunk path for moving between two meshchunks, returns empty list if impossible
func get_mc_path(from, to):
	#caching
	if from == prevfrom and to == prevto:
		return prevresult
	var pp = astarmap.get_id_path(from.id, to.id)
	var list = []
	for id in pp:
		list.append(id2chunk[id])
	prevfrom = from
	prevto = to
	prevresult = list
	return list.duplicate()

func get_vec_path(from, to):
	var path = get_mc_path(from, to)
	var vecpath = []
	for mc in path:
		vecpath.append(mc.get_platform_pos() + Vector3(0, 1, 0))
	return vecpath

func _update_annotation_color(newcolor):
	if annotationMaterial.albedo_color != newcolor:
		annotationMaterial.albedo_color = newcolor

func _reset_annotation_color():
	_update_annotation_color(Color(1, 0.8, 0.2))

func _set_move_annotation_color(path, cost):
	var valid = Global.selected_player.is_move_valid(path, cost)
	if valid:
		_reset_annotation_color()
	else:
		_update_annotation_color(Color(1, 0, 0))

func get_enemy_on_tile(mapchunk):
	if !is_instance_valid(mapchunk):
		return null
	var occupant = mapchunk.occupant
	if !is_instance_valid(occupant):
		return null
	if occupant.has_method("is_enemy") && occupant.is_enemy():
		return occupant
	return null

var prevselected = null
func _physics_process(delta: float) -> void:
	while len(Global.unhandled_input_queue) > 0:
		var event = Global.unhandled_input_queue.pop_front()
		# TODO: Handle input
		if (event is InputEventMouseButton) and (event.button_index == BUTTON_LEFT) and (!event.pressed):
			var clicked = $Camera.get_selectable_at_point(event.position)
			if is_instance_valid(clicked):
				if clicked.has_method("is_player") and !is_instance_valid(Global.selected_player):
					Global.selected_player = clicked
				elif Global.is_move_skill_selected() and is_instance_valid(Global.selected_player):
					Global.selected_player.move(get_mc_path(prevfrom, prevto), Global.current_movecost)
				elif Global.is_attack_skill_selected() and is_instance_valid(Global.selected_player):
					Global.selected_player.attack(clicked)
		if (event is InputEventMouseMotion):
			if is_instance_valid(prevselected):
				prevselected.set_unselected(Global.SelectMask.MOUSE_OVER)
			prevselected = $Camera.get_scenery_at_point(event.position)
			if is_instance_valid(prevselected):
				prevselected.set_selected(Global.SelectMask.MOUSE_OVER)
				if Global.is_move_skill_selected() and is_instance_valid(Global.selected_player):
					$LineRenderer.visible = true
					var path = get_vec_path(Global.selected_player.map_chunk, prevselected)
					$LineRenderer.points = path
					Global.current_movecost = ceil((len(path) - 1) / Global.selected_player.speed)
					_set_move_annotation_color(get_mc_path(Global.selected_player.map_chunk, prevselected), Global.current_movecost)
				elif Global.is_attack_skill_selected() and is_instance_valid(Global.selected_player):
					var enemy = get_enemy_on_tile(prevselected)
					if is_instance_valid(enemy) and Global.selected_player.is_attack_valid(enemy):
						$LineRenderer.visible = true
						$LineRenderer.points = [Global.selected_player.translation + Vector3(0, 4, 0), enemy.translation + Vector3(0, 4, 0)]
						_reset_annotation_color()
					else:
						$LineRenderer.visible = false
						_update_annotation_color(Color(1, 0, 0))
				else:
					$LineRenderer.visible = false
					_reset_annotation_color()
				
		if event.is_action_pressed("ui_cancel"):
			Global.selected_player = null
