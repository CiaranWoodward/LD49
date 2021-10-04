extends RigidBody

signal stats_changed

export var move_animation_speed : float = 30.0
export var max_ap : int = 4
export var max_health : int = 5
export var speed : float = 2.0
export var mindamage : int = 6
export var maxdamage : int = 9
export(SpatialMaterial) var laserMaterial = null

const golem_type = Global.EnemyType.Melee

var map_chunk = null
var id = 0
var ap = max_ap
var health = max_health
var selected = false
var state = Global.EnemyState.Idle
var target = Global.EnemyTarget.Crystal
var target_chunk = null
var path = []
var projectile_offset = Vector3(0, 2, 0)
var laser

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
	laser = preload("res://LineRenderer/LineRenderer.tscn").instance()
	laser.material_override = laserMaterial

func is_enemy():
	return true

func damage(dam):
	health -= dam
	if health < 0:
		Global.remove_enemy(self)
		_change_chunk(null)
		stateMachine.travel("Die")
		tween.interpolate_callback(self, 2, "queue_free")
	else:
		stateMachine.travel("Hit")

func _find_closest_target():
	var my_pos = Vector2(map_chunk.x, map_chunk.z)
	var best_target = Global.EnemyTarget.Crystal
	var best_chunk = Global.map.get_chunk(0, 0)
	var best_distance = my_pos.distance_to(Vector2.ZERO)
	for player in Global.players:
		var dist = my_pos.distance_to(Vector2(player.map_chunk.x, player.map_chunk.z))
		if dist < best_distance and (Global.is_adjacent_mc(player.map_chunk, map_chunk) or len(Global.map.get_mc_path(map_chunk, player.map_chunk)) > 0):
			best_target = Global.EnemyTarget.Player
			best_chunk = player.map_chunk
			best_distance = dist
	if Global.is_adjacent_mc(best_chunk, map_chunk) or (len(Global.map.get_mc_path(map_chunk, best_chunk)) > 0):
		target = best_target
		target_chunk = best_chunk
	else:
		target_chunk = null

func _can_hit(target) -> bool:
	var space_state = get_world().direct_space_state
	var from = translation + projectile_offset
	var to = target.translation + projectile_offset
	var colinfo = space_state.intersect_ray(from, to, [], Global.CollisionLayer.SCENERY)
	return len(colinfo) == 0

func draw_laser(target):
	laser.points = [target.translation + projectile_offset, translation + projectile_offset]
	get_parent().add_child(laser)
	tween.interpolate_callback(self, 1, "undraw_laser")

func undraw_laser():
	get_parent().remove_child(laser)
	Global.next_enemy()

func _try_hit_crystal() -> bool:
	var crystal = Global.map.get_chunk(0, 0).occupant
	if _can_hit(crystal):
		Global.damage_crystal(10)
		draw_laser(crystal)
		return true
	return false

func _try_hit_player() -> bool:
	var playerlist = Global.players.duplicate()
	playerlist.shuffle()
	for player in playerlist:
		if _can_hit(player):
			player.damage((randi() % (maxdamage - mindamage + 1)) + mindamage)
			draw_laser(player)
			return true
	return false

func _handle_enemy_changed(enemy):
	if enemy == self:
		ap = max_ap
		_find_closest_target()
		if is_instance_valid(target_chunk):
			if !Global.is_adjacent_mc(map_chunk, target_chunk):
				var path = Global.map.get_mc_path(map_chunk, target_chunk)
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
		else:
			Global.next_enemy()

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
	if (randi() % 3) == 0:
		if !_try_hit_crystal():
			if !_try_hit_player():
				Global.next_enemy()
	else:
		if !_try_hit_player():
			if !_try_hit_crystal():
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
