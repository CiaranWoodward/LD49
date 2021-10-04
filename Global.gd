tool
extends Node

signal player_selected(id, player)
signal skill_selected(id)
signal gamestate_changed(newstate)
signal players_modified()
signal movecost_calculated(newcost)
signal paused_changed(newstate)

enum CollisionLayer {
	SCENERY = 1<<0,
	SELECTABLE_SCENERY = 1<<10,
	SELECTABLE_PLAYER = 1<<11,
	SELECTABLE_ENEMY = 1<<12,
	SELECTABLE_ALL = 1<<10 | 1<<11 | 1<<12
}

enum SelectMask {
	MOUSE_OVER = 1<<0,
	PLAYER_ON = 1<<1
}

enum SkillType {
	None, Crater, Raise, Ranged, Melee, MoveMelee, MoveRanged, NextTurn
}

enum GameState {
	PlayerTurn, EnemyTurn, MapTurn
}

enum PlayerState {
	Idle, Moving, Attacking
}

enum GolemType { Melee, Ranged }

var unhandled_input_queue = []
var map = null
var hud = null
var players = []
var paused = true setget _set_paused

var selected_player = null setget _set_selected_player
var selected_skill = SkillType.None setget _set_selected_skill
var current_gamestate = GameState.PlayerTurn
var current_movecost = 0 setget _set_movecost

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _set_paused(new):
	paused = new
	emit_signal("paused_changed", paused)

func _set_selected_player(new):
	selected_player = new
	emit_signal("player_selected", players.find(new), new)
	if !is_instance_valid(new):
		_set_selected_skill(SkillType.None)

func _set_selected_skill(new):
	selected_skill = new
	emit_signal("skill_selected", new)

func _set_gamestate(new):
	current_gamestate = new
	emit_signal("gamestate_changed", new)

func _set_movecost(new):
	if new == current_movecost:
		return
	current_movecost = new
	emit_signal("movecost_calculated", new)

func add_player(new_player):
	players.append(new_player)
	emit_signal("players_modified")

func is_move_skill_selected():
	return (selected_skill == SkillType.MoveMelee or selected_skill == SkillType.MoveRanged)
