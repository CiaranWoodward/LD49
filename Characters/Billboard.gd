tool
extends Spatial

export(Vector2) var output_size = Vector2(5, 5) setget set_output_size
export(PackedScene) var scene : PackedScene = null

var scene2d : Node2D = null

func set_output_size(new):
	output_size = new
	$ViewportQuad.mesh.size = new
	$ShadowCaster.mesh.mid_height = new.y/2

func set_scene(new):
	scene = new
	_clear_viewport_children()
	if !is_instance_valid(scene):
		print("Error: No billboard scene configured")
		return
	# Configure the output size and viewport
	var childscene = scene.instance()
	var scenecontents = childscene.get_children()
	var found = false
	for ch in scenecontents:
		if ch.has_method("get_viewport_camera_bounds"):
			$Viewport.size = ch.get_viewport_camera_bounds()
			found = true
			break
	if !found:
		print("Error: No viewport camera in billboard scene")
	# Add the scene to viewport
	$Viewport.add_child(childscene)
	scene2d = childscene
	print("added viewport child scene")
	if Engine.editor_hint:
		childscene.owner = get_tree().edited_scene_root

func _clear_viewport_children():
	for ch in $Viewport.get_children():
		ch.queue_free()

func _ready():
	set_output_size(output_size)
	set_scene(scene)
	
	# Clear the viewport.
	var viewport = $Viewport
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)

	# Retrieve the texture and set it to the viewport quad.
	var tex =  viewport.get_texture()
	
	$ViewportQuad.material_override = SpatialMaterial.new()
	$ViewportQuad.material_override.flags_transparent = true
	$ViewportQuad.material_override.flags_do_not_receive_shadows = true
	$ViewportQuad.material_override.params_billboard_mode = SpatialMaterial.BILLBOARD_ENABLED
	$ViewportQuad.material_override.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
	$ViewportQuad.material_override.albedo_texture = tex

func get_childscene() -> Node2D:
	return scene2d
