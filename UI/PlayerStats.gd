extends Control

export var golem_number : int = 0

var my_golem = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_evaluate_necessity()
	Global.connect("players_modified", self, "_evaluate_necessity")
	Global.connect("player_selected", self, "_global_player_selected")

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		Global.selected_player = Global.players[golem_number]

func _evaluate_necessity():
	if len(Global.players) - 1 < golem_number:
		self.visible = false
		my_golem = null
	else:
		self.visible = true
		my_golem = Global.players[golem_number]

func _global_player_selected(id, player):
	if id == golem_number:
		$Border.visible = true
	else:
		$Border.visible = false
