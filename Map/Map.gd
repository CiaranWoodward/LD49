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

# Map array
var maparr = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	_initial_mapgen()

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

func get_chunk(x : int, z : int):
	if abs(x * z) > (radius * radius):
		return null
	return maparr[x + radius][z + radius]

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
