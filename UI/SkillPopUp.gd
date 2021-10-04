extends Control


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
var default_fallback = false
var current_show = Global.SkillType.None

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.connect("skill_selected", self, "_handle_skill_selected")
	for desc in $"NinePatchRect/MarginContainer".get_children():
		desc.visible = false
	self.visible = false

func _handle_skill_selected(id):
	if default_fallback:
		_showtype(id)

func showtype(showtype):
	if showtype == Global.SkillType.None:
		default_fallback = true
		showtype = Global.selected_skill
	else:
		default_fallback = false
	_showtype(showtype)

func _showtype(showtype):
	self.visible = (showtype != Global.SkillType.None)
	for desc in $"NinePatchRect/MarginContainer".get_children():
		desc.visible = false
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
		Global.SkillType.NextTurn:
			$NinePatchRect/MarginContainer/EndTurn.visible = true
