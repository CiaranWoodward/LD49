extends MeshInstance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_degrees.y = (randi() % 4) * 90
