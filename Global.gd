tool
extends Node

signal player_selected(id, player)
signal enemy_selected(enemy)
signal skill_selected(id)
signal gamestate_changed(newstate)
signal players_modified()
signal movecost_calculated(newcost)
signal paused_changed(newstate)
signal crystalstability_changed(newval)

enum CollisionLayer {
	SCENERY = 1<<0,
	SELECTABLE_SCENERY = 1<<10,
	SELECTABLE_PLAYER = 1<<11,
	SELECTABLE_ENEMY = 1<<12,
	SELECTABLE_ALL = 1<<10 | 1<<11 | 1<<12
}

enum SelectMask {
	MOUSE_OVER = 1<<0,
	PLAYER_ON = 1<<1,
	ENEMY_ON = 1<<2,
}

enum SkillType {
	None, Crater, Raise, Ranged, Melee, MoveMelee, MoveRanged, NextTurn
}

enum GameState {
	PlayerTurn, EnemyTurn, MapTurn, GameOver
}

enum PlayerState {
	Idle, Moving, Attacking
}

enum EnemyState {
	Idle, Moving, Attacking
}

enum EnemyTarget { Crystal, Player }

enum GolemType { Melee, Ranged }

enum EnemyType { Baby, Melee, Ranged }

var unhandled_input_queue = []
var map = null
var hud = null
var players = []
var enemies = []
var enemy_iterator = 0
var map_countdown = 2
var crystal_health : int = 1
var paused = true setget _set_paused

var selected_player = null setget _set_selected_player
var selected_enemy = null
var selected_skill = SkillType.None setget _set_selected_skill
var current_gamestate = GameState.PlayerTurn setget _set_gamestate
var current_movecost = 0 setget _set_movecost

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _set_paused(new):
	paused = new
	emit_signal("paused_changed", paused)

func _set_selected_player(new):
	if current_gamestate != GameState.PlayerTurn:
		return
	selected_player = new
	emit_signal("player_selected", players.find(new), new)
	if !is_instance_valid(new):
		_set_selected_skill(SkillType.None)

func _set_selected_skill(new):
	if current_gamestate != GameState.PlayerTurn:
		return
	selected_skill = new
	if selected_skill == SkillType.NextTurn:
		selected_skill = SkillType.None
		_set_selected_player(null)
		_set_gamestate(GameState.EnemyTurn)
	emit_signal("skill_selected", new)

func _set_gamestate(new):
	current_gamestate = new
	if current_gamestate == GameState.EnemyTurn:
		enemy_iterator = 0
		next_enemy()
	if current_gamestate == GameState.MapTurn:
		if map_countdown == 0:
			map_countdown = (randi() % 3) + 1
			map._regen_map()
		else:
			map_countdown -= 1
			call_deferred("regen_done")
	emit_signal("gamestate_changed", new)

func _set_movecost(new):
	if new == current_movecost:
		return
	current_movecost = new
	emit_signal("movecost_calculated", new)

func next_enemy():
	if enemy_iterator >= len(enemies):
		_set_gamestate(GameState.MapTurn)
	else:
		selected_enemy = enemies[enemy_iterator]
		enemy_iterator += 1
		emit_signal("enemy_selected", selected_enemy)

func is_adjacent(x1, z1, x2, z2):
	if abs(x1 - x2) <= 1 and abs(z1 - z2) <= 1:
		return true
	return false

func is_adjacent_mc(m1, m2):
	return is_adjacent(m1.x, m1.z, m2.x, m2.z)

func add_player(new_player):
	players.append(new_player)
	emit_signal("players_modified")

func add_enemy(new_enemy):
	enemies.append(new_enemy)

func remove_enemy(enem):
	enemies.erase(enem)

func damage_crystal(dam):
	crystal_health -= dam
	crystal_health = int(clamp(crystal_health, 0, 100))
	emit_signal("crystalstability_changed", crystal_health)
	if crystal_health <= 0:
		_set_gamestate(GameState.GameOver)

func regen_done():
	if current_gamestate == GameState.MapTurn:
		_set_gamestate(GameState.PlayerTurn)

func is_move_skill_selected():
	return (selected_skill == SkillType.MoveMelee or selected_skill == SkillType.MoveRanged)

func is_attack_skill_selected():
	return (selected_skill == SkillType.Ranged or selected_skill == SkillType.Melee)
