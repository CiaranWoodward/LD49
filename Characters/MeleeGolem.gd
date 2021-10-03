extends RigidBody

var map_chunk = null
var id = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.add_player(self)
	id = len(Global.players) - 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(map_chunk):
		self.translation = map_chunk.get_platform_visual_pos()
	else:
		map_chunk = Global.map.get_random_chunk()
