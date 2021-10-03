extends HBoxContainer

var namemap = {
	"MoveMelee" : Global.SkillType.MoveMelee,
	"MoveRanged" : Global.SkillType.MoveRanged,
	"Melee" : Global.SkillType.Melee,
	"Ranged" : Global.SkillType.Ranged,
	"Raise" : Global.SkillType.Raise,
	"Crater" : Global.SkillType.Crater
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		child.connect("mouse_entered", self, "_mouse_entered", [child.name])
		child.connect("mouse_exited", self, "_mouse_exited", [child.name])
	Global.connect("player_selected", self, "_player_selected")

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
		self.visible = false

func _mouse_entered(item):
	Global.hud.get_node("root/SkillPopUp").showtype(namemap[item])

func _mouse_exited(item):
	Global.hud.get_node("root/SkillPopUp").showtype(Global.SkillType.None)
