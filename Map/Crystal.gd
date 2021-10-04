extends RigidBody

var map_chunk = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(map_chunk):
		self.translation = map_chunk.get_platform_visual_pos()
