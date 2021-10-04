extends CanvasLayer

onready var animTree : AnimationTree = get_node("AnimationTree")
onready var stateMachine : AnimationNodeStateMachinePlayback = animTree["parameters/playback"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animTree.active = true
	stateMachine.start("Start")

func _on_PlayButton_pressed() -> void:
	stateMachine.travel("Intro")

func _on_Intro_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		stateMachine.travel("FadeOut")
		Global.paused = false
