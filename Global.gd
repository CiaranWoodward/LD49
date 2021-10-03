tool
extends Node

signal player_selected(id, player)
signal skill_selected(id)
signal gamestate_changed(newstate)
signal players_modified()

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

enum GolemType { Melee, Ranged }

var unhandled_input_queue = []
var map = null
var hud = null
var players = []

var selected_player = null setget _set_selected_player
var selected_skill = SkillType.None setget _set_selected_skill
var current_gamestate = GameState.PlayerTurn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _set_selected_player(new):
	selected_player = new
	emit_signal("player_selected", players.find(new), new)

func _set_selected_skill(new):
	selected_skill = new
	emit_signal("skill_selected", new)

func _set_gamestate(new):
	current_gamestate = new
	emit_signal("gamestate_changed", new)

func add_player(new_player):
	players.append(new_player)
	emit_signal("players_modified")
