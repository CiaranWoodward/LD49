extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.hud = self
	Global.connect("paused_changed", self, "_handle_paused")

func _handle_paused(paused):
	if !paused:
		$AnimationPlayer.play("FadeIn")
