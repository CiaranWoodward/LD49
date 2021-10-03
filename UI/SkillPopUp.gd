extends Control


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func showtype(showtype):
	for desc in $"NinePatchRect/MarginContainer".get_children():
		desc.visible = false
	if showtype == Global.SkillType.None:
		self.visible = false
		return
	self.visible = true
	match showtype:
		Global.SkillType.Crater:
			$NinePatchRect/MarginContainer/Crater.visible = true
		Global.SkillType.Raise:
			$NinePatchRect/MarginContainer/Raise.visible = true
		Global.SkillType.Ranged:
			$NinePatchRect/MarginContainer/Ranged.visible = true
		Global.SkillType.Melee:
			$NinePatchRect/MarginContainer/Melee.visible = true
		Global.SkillType.MoveMelee:
			$NinePatchRect/MarginContainer/MoveMelee.visible = true
		Global.SkillType.MoveRanged:
			$NinePatchRect/MarginContainer/MoveRanged.visible = true
