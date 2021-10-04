extends RigidBody

export var max_ap : int = 10
export var speed : float = 4.0

const golem_type = Global.GolemType.Melee

var map_chunk = null
var id = 0
var ap = max_ap
var selected = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.add_player(self)
	id = len(Global.players) - 1
	Global.connect("player_selected", self, "_handle_player_selected")

func _handle_player_selected(_id, player):
	if selected && player != self:
		selected = false
		map_chunk.set_unselected(Global.SelectMask.PLAYER_ON)
	if !selected && player == self:
		selected = true
		map_chunk.set_selected(Global.SelectMask.PLAYER_ON)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(map_chunk):
		self.translation = map_chunk.get_platform_visual_pos()
	else:
		map_chunk = Global.map.get_random_chunk()
