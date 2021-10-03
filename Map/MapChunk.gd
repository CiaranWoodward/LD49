tool
extends RigidBody

const width = 5.0

var height = 10.0

var verts : PoolVector3Array
var normals : PoolVector3Array
var colors : PoolColorArray
var plat_height : float = 0
var topperheight : float = 1

# For the A* algorithm tracking
var id = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	topperheight = $GrassTopper.mesh.size.y
	_regenerate_mesh()

func _regenerate_mesh() -> void:
	var cm = CubeMesh.new()
	cm.size = Vector3(width, height - topperheight, width)
	var arr = cm.get_mesh_arrays()
	arr.resize(Mesh.ARRAY_MAX)
	
	var am = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	$Mesh.mesh = am
	
	_set_visual_relative_height(self.plat_height)
	
	# Move down so we have a fixed top
	self.translation.y = -height/2
	_regenerate_collision()

func _regenerate_collision() -> void:
	$CollisionShape.shape.extents = Vector3(width/2, height/2, width/2)

func _set_visual_relative_height(rel_height):
	#Move the topper to the correct place
	$Mesh.translation.y = -topperheight/2 + rel_height
	$GrassTopper.translation.y = height/2 - topperheight/2 + rel_height

# Displace by a value in the range [-1, 1]
func set_displacement(displace : float, tweentime : float = 1.5):
	var old_plat_height = self.plat_height
	self.plat_height = (displace * height)
	var plat_height_diff = old_plat_height - plat_height
	self.translation.y = plat_height - (height/2)
	tweentime *= rand_range(0.9, 1.1)
	_set_visual_relative_height(plat_height_diff)
	$Tween.interpolate_method(self, "_set_visual_relative_height", plat_height_diff, 0, tweentime, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	$Tween.start()

func get_platform_pos() -> Vector3:
	var retval = self.translation
	retval.y += height/2
	return retval

func set_selected(selected : bool):
	$"GrassTopper/Selected".visible = selected

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
