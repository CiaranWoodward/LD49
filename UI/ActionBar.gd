extends HBoxContainer

var namemap = {
	"MoveMelee" : Global.SkillType.MoveMelee,
	"MoveRanged" : Global.SkillType.MoveRanged,
	"Melee" : Global.SkillType.Melee,
	"Ranged" : Global.SkillType.Ranged,
	"Raise" : Global.SkillType.Raise,
	"Crater" : Global.SkillType.Crater,
	"NextTurn" : Global.SkillType.NextTurn
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		child.connect("mouse_entered", self, "_mouse_entered", [child.name])
		child.connect("mouse_exited", self, "_mouse_exited", [child.name])
		child.connect("toggled", self, "_skill_toggled", [child.name])
	self.visible = true
	_player_selected(0, null)
	Global.connect("player_selected", self, "_player_selected")
	Global.connect("skill_selected", self, "_skill_selected")
	Global.connect("gamestate_changed", self, "_gamestate_changed")

func _player_selected(id, player):
	if is_instance_valid(player):
		self.visible = true
		var melee = (player.golem_type == Global.GolemType.Melee)
		$MoveMelee.visible = melee
		$Melee.visible = melee
		$Raise.visible = melee
		$MoveRanged.visible = !melee
		$Ranged.visible = !melee
		$Crater.visible = !melee
	else:
		Global.selected_skill = Global.SkillType.None
		for child in get_children():
			if child == $NextTurn: continue
			child.visible = false
			child.pressed = false

func _gamestate_changed(state):
	if state == Global.GameState.PlayerTurn:
		$NextTurn.visible = true
	else:
		$NextTurn.visible = false

func _skill_selected(id):
	for child in get_children():
		child.pressed = (namemap[child.name] == id)

func _skill_toggled(pressed, name):
	if !pressed and Global.selected_skill == namemap[name]:
		Global.selected_skill = Global.SkillType.None
	if pressed and Global.selected_skill != namemap[name]:
		Global.selected_skill = namemap[name]

func _mouse_entered(item):
	Global.hud.get_node("root/SkillPopUp").showtype(namemap[item])

func _mouse_exited(item):
	Global.hud.get_node("root/SkillPopUp").showtype(Global.SkillType.None)
