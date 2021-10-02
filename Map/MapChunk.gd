extends MeshInstance

const width = 5.0
tool

var height = 10.0

var verts : PoolVector3Array
var normals : PoolVector3Array
var colors : PoolColorArray


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_regenerate_mesh()

func _regenerate_mesh() -> void:
	var cm = CubeMesh.new()
	cm.size = Vector3(width, height, width)
	var arr = cm.get_mesh_arrays()
	arr.resize(Mesh.ARRAY_MAX)
	
	var am = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	self.mesh = am
	
	# Move down so we have a fixed top
	self.translation.y = -height/2

# Displace by a value in the range [-1, 1]
func set_displacement(displace : float):
	self.translation.y = (displace * height) - (height/2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass