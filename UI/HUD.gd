extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.hud = self
	Global.connect("paused_changed", self, "_handle_paused")
	Global.connect("gamestate_changed", self, "_handle_gamestate")
	_handle_gamestate(Global.current_gamestate)

func _handle_paused(paused):
	if !paused:
		$AnimationPlayer.play("FadeIn")

func _handle_gamestate(newstate):
	if newstate == Global.GameState.EnemyTurn:
		$root/Turn.text = "Shadow Turn"
	elif newstate == Global.GameState.MapTurn:
		$root/Turn.text = "Crystal Turn"
	elif newstate == Global.GameState.PlayerTurn:
		$root/Turn.text = "Player Turn"
	elif newstate == Global.GameState.GameOver:
		$root/Turn.text = "Game Over"
