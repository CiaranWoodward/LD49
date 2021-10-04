extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.connect("crystalstability_changed", self, "_handle_crystal_stability")
	_handle_crystal_stability(Global.crystal_health)

func _handle_crystal_stability(newval):
	$TextureProgress.value = newval
