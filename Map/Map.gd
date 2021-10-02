tool
extends Spatial

# References to other scenes
const MapChunk = preload("res://Map/MapChunk.tscn")

# Map generation parameters
export var radius : int = 15;
export var minheight : float = 0.5
export var maxheightc : float = 28.0
export var gradient : float = 0.25

# Map array
var maparr = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initial_mapgen()

func _initial_mapgen() -> void:
	maparr.resize((radius+1) * 2)
	for x in range(len(maparr)):
		maparr[x] = []
		maparr[x].resize((radius+1) * 2)
	for x in range(-radius, radius+1):
		for z in range(-radius, radius+1):
			_gen_chunk(x, z)

func get_chunk(x : int, z : int):
	if abs(x * z) > (radius * radius):
		return null
	return maparr[x + radius][z + radius]

func _gen_chunk(x : int, z : int) -> void:
	var dist = sqrt(x*x + z*z)
	if dist > radius:
		return
	var mc = MapChunk.instance()
	mc.height = pow(2, (maxheightc - dist) * gradient) + minheight
	maparr[x + radius][z + radius] = mc
	mc.translation = Vector3(x * mc.width, 0, z * mc.width)
	add_child(mc)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
