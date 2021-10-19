extends RigidBody

signal stats_changed

export var move_animation_speed : float = 30.0
export var max_ap : int = 6
export var max_health : int = 30
export var speed : float = 3.0
export var attack_ap : int = 2
export var damage_min : int = 4
export var damage_max : int = 6

const golem_type = Global.GolemType.Ranged

var map_chunk = null
var id = 0
var ap = max_ap
var health = max_health
var selected = false
var state = Global.PlayerState.Idle
var path = []
var projectile_offset = Vector3(0, 4, 0)

onready var tween : Tween = Tween.new()
onready var scene2d : Node2D = $SceneBillboard.scene2d
onready var animTree : AnimationTree = scene2d.get_node("AnimationTree")
onready var stateMachine : AnimationNodeStateMachinePlayback = animTree["parameters/StateMachine/playback"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(tween)
	Global.add_player(self)
	id = len(Global.players) - 1
	Global.connect("player_selected", self, "_handle_player_selected")
	Global.connect("gamestate_changed", self, "_handle_gamestate_changed")
	animTree.active = true
	stateMachine.start("Idle")

func is_player():
	return true

func _handle_player_selected(_id, player):
	if selected && player != self:
		selected = false
		map_chunk.set_unselected(Global.SelectMask.PLAYER_ON)
	if !selected && player == self:
		selected = true
		map_chunk.set_selected(Global.SelectMask.PLAYER_ON)

func _handle_gamestate_changed(newstate):
	if newstate == Global.GameState.PlayerTurn:
		if state == Global.PlayerState.Dead:
			ap = 0
		else:
			ap = max_ap
		emit_signal("stats_changed")

func is_attack_valid(enemy) -> bool:
	if is_instance_valid(enemy) and enemy.has_method("is_enemy") and enemy.is_enemy():
		var space_state = get_world().direct_space_state
		var from = translation + projectile_offset
		var to = enemy.translation + projectile_offset
		var colinfo = space_state.intersect_ray(from, to, [], Global.CollisionLayer.SCENERY)
		if ap >= attack_ap and len(colinfo) == 0:
			return true
	return false

func attack(enemy) -> bool:
	if is_attack_valid(enemy):
		var damage = (randi() % (damage_max + 1 - damage_min)) + damage_min
		ap -= attack_ap
		emit_signal("stats_changed")
		stateMachine.travel("FrontAttack")
		var proj = preload("res://Characters/Projectile.tscn").instance()
		proj.target = enemy
		proj.damage = damage
		get_parent().add_child(proj)
		proj.translation = translation + projectile_offset
		return true
	return false

func damage(dam):
	health -= dam
	if health < 0:
		stateMachine.travel("Die")
		state = Global.PlayerState.Dead
	else:
		stateMachine.travel("Hit")
	emit_signal("stats_changed")

func is_move_valid(pathf, cost) -> bool:
	if cost > ap:
		return false
	if len(pathf) == 0:
		return false
	if is_instance_valid(pathf.back().occupant):
		return false
	if state != Global.PlayerState.Idle:
		return false
	return true

func move(pathf, cost) -> bool:
	if pathf.front() == map_chunk:
		pathf.pop_front()
	if !is_move_valid(pathf, cost):
		return false
	ap -= cost
	emit_signal("stats_changed")
	_change_state(Global.PlayerState.Moving)
	self.path = pathf
	_change_chunk(path.back())
	# Follow the path, then unset state
	Global.selected_skill = Global.SkillType.None
	_animate_nextstep(true)
	return true

func _animate_nextstep(first = false):
	print("animating next step")
	var trans = Tween.TRANS_LINEAR
	var easing = Tween.EASE_IN
	if first:
		trans = Tween.TRANS_SINE
	if len(path) == 1:
		easing = Tween.EASE_OUT
	var nextc = path.pop_front()
	var time = self.translation.distance_to(nextc.get_platform_visual_pos()) / move_animation_speed
	tween.stop(self, "translation")
	tween.interpolate_property(self, "translation", translation, nextc.get_platform_visual_pos(), time)
	tween.interpolate_callback(self, time, "_animate_nextstep_done")
	tween.start()

func _animate_nextstep_done():
	if len(path) == 0:
		_change_state(Global.PlayerState.Idle)
	else:
		_animate_nextstep()

func _change_state(newstate):
	if newstate == Global.PlayerState.Moving:
		stateMachine.travel("Walk")
	if newstate == Global.PlayerState.Idle:
		stateMachine.travel("Idle")
	state = newstate

func _change_chunk(newchunk):
	if is_instance_valid(map_chunk):
		if selected:
			map_chunk.set_unselected(Global.SelectMask.PLAYER_ON)
		map_chunk.occupant = null
	if is_instance_valid(newchunk):
		if selected:
			newchunk.set_selected(Global.SelectMask.PLAYER_ON)
		newchunk.occupant = self
	map_chunk = newchunk

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == Global.PlayerState.Moving:
		pass
	elif state == Global.PlayerState.Dead:
		pass
	else:
		if is_instance_valid(map_chunk):
			self.translation = map_chunk.get_platform_visual_pos()
		else:
			_change_chunk(Global.map.get_random_chunk())
