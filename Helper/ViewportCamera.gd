tool
extends Camera2D

export(Vector2) var bounds = Vector2(400, 400) setget set_bounds
export(bool) var editor_visible = true setget set_visible

func set_bounds(new_bounds):
	bounds = new_bounds
	$CollisionShape2D.shape.extents = new_bounds / 2

func set_visible(new):
	editor_visible = new
	$CollisionShape2D.visible = new

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_bounds(bounds)

func get_viewport_camera_bounds() -> Vector2:
	return bounds
