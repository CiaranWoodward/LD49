extends HBoxContainer

var namemap = {
	"Move" : Global.SkillType.MoveMelee,
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

func _mouse_entered(item):
	Global.hud.get_node("root/SkillPopUp").showtype(namemap[item])

func _mouse_exited(item):
	Global.hud.get_node("root/SkillPopUp").showtype(Global.SkillType.None)
