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
		my_golem.connect("stats_changed", self, "_stat_update")
		_stat_update()

func _global_player_selected(id, player):
	if id == golem_number:
		$Border.visible = true
	else:
		$Border.visible = false

func _stat_update():
	$HBoxContainer/AP/VBox/Label.text = str(my_golem.ap) + "/" + str(my_golem.max_ap)
	$HBoxContainer/Health/VBox/Label.text = str(my_golem.health) + "/" + str(my_golem.max_health)
