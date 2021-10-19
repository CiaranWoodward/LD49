extends RigidBody

signal stats_changed

export var move_animation_speed : float = 30.0
export var max_ap : int = 5
export var max_health : int = 7
export var speed : float = 2.0

const golem_type = Global.EnemyType.Baby

var map_chunk = null
var id = 0
var ap = max_ap
var health = max_health
var selected = false
var state = Global.EnemyState.Idle
var target = Global.EnemyTarget.Crystal
var path = []

onready var tween : Tween = Tween.new()
onready var scene2d : Node2D = $SceneBillboard.scene2d
onready var animTree : AnimationTree = scene2d.get_node("AnimationTree")
onready var stateMachine : AnimationNodeStateMachinePlayback = animTree["parameters/StateMachine/playback"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(tween)
	Global.add_enemy(self)
	Global.connect("enemy_selected", self, "_handle_enemy_changed")
	animTree.active = true
	stateMachine.start("Spawn")

func is_enemy():
	return true

func damage(dam):
	health -= dam
	if health < 0:
		Global.remove_enemy(self)
		_change_chunk(null)
		stateMachine.travel("Die")
		tween.interpolate_callback(self, 2, "queue_free")
		tween.start()
		collision_layer = 0
	else:
		stateMachine.travel("Hit")

func _handle_enemy_changed(enemy):
	if enemy == self:
		ap = max_ap
		if !Global.is_adjacent(map_chunk.x, 0, map_chunk.z, 0):
			var target = Global.map.get_unoccupied_crystal_space()
			var path = Global.map.get_mc_path(map_chunk, target)
			if len(path) == 0:
				Global.next_enemy()
				return
			var max_dist = get_max_path_len_for_cost(ap)
			if max_dist < len(path):
				path.resize(max_dist)
			while path.back().is_occupied():
				path.pop_back()
				if len(path) == 0:
					Global.next_enemy()
					return
			move(path, get_path_cost(path))
		else:
			_handle_attacking()

func get_max_path_len_for_cost(cost):
	return cost * speed

func get_path_cost(path):
	return ceil(len(path) / speed)

func is_move_valid(pathf, cost) -> bool:
	if cost > ap:
		return false
	if len(pathf) == 0:
		return false
	if is_instance_valid(pathf.back().occupant):
		return false
	if state != Global.EnemyState.Idle:
		return false
	return true

func move(pathf, cost) -> bool:
	if pathf.front() == map_chunk:
		pathf.pop_front()
	if !is_move_valid(pathf, cost):
		return false
	ap -= cost
	emit_signal("stats_changed")
	_change_state(Global.EnemyState.Moving)
	self.path = pathf
	_change_chunk(path.back())
	# Follow the path, then unset state
	Global.selected_skill = Global.SkillType.None
	_animate_nextstep(true)
	return true

func _handle_attacking():
	if Global.is_adjacent(map_chunk.x, 0, map_chunk.z, 0):
		stateMachine.travel("Die")
		Global.damage_crystal(10)
	Global.next_enemy()

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
		_change_state(Global.EnemyState.Idle)
		_handle_attacking()
	else:
		_animate_nextstep()

func _change_state(newstate):
	if newstate == Global.EnemyState.Moving:
		stateMachine.travel("Walk")
	if newstate == Global.EnemyState.Idle:
		stateMachine.travel("Idle")
	state = newstate

func _change_chunk(newchunk):
	if is_instance_valid(map_chunk):
		if selected:
			map_chunk.set_unselected(Global.SelectMask.ENEMY_ON)
		map_chunk.occupant = null
	if is_instance_valid(newchunk):
		if selected:
			newchunk.set_selected(Global.SelectMask.ENEMY_ON)
		newchunk.occupant = self
	map_chunk = newchunk

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == Global.EnemyState.Moving:
		pass
	else:
		if is_instance_valid(map_chunk):
			self.translation = map_chunk.get_platform_visual_pos()
		elif health > 0:
			_change_chunk(Global.map.get_random_edge_chunk())
