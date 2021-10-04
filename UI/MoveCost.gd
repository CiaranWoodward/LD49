extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.connect("movecost_calculated", self, "_handle_updated_cost")

func _handle_updated_cost(newcost):
	if newcost == 0:
		text = "Invalid move."
	elif newcost == 1:
		text = "Costs 1 action point."
	else:
		text = "Costs " + str(newcost) + " action points."
