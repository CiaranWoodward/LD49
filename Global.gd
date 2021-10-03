tool
extends Node

enum CollisionLayer {
	SCENERY = 1<<0,
	SELECTABLE_SCENERY = 1<<10
}

enum SkillType {
	None, Crater, Raise, Ranged, Melee, MoveMelee, MoveRanged
}

enum GameState {
	PlayerTurn, EnemyTurn, MapTurn
}

var unhandled_input_queue = []
var map = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
