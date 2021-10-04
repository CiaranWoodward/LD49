extends CanvasLayer

onready var animTree : AnimationTree = get_node("AnimationTree")
onready var stateMachine : AnimationNodeStateMachinePlayback = animTree["parameters/playback"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animTree.active = true
	stateMachine.start("Start")
	Global.connect("gamestate_changed", self, "_handle_gamestate")

func _on_PlayButton_pressed() -> void:
	stateMachine.travel("Intro")

func _on_Intro_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		stateMachine.travel("FadeOut")
		Global.paused = false

func _handle_gamestate(newstate):
	if newstate == Global.GameState.GameOver:
		stateMachine.start("Fail")
	if newstate == Global.GameState.GameWin:
		stateMachine.start("End")
