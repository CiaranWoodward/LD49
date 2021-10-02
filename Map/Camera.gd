extends Camera

export var MAX_HEIGHT : float = 95.0
export var MIN_HEIGHT : float = 20.0
export var distance : float = 120.0
export var MAX_SPEED = 10.0
export var ACCEL_TIME = 0.5
export var STOP_TIME = 0.2

onready var tween = get_node("Tween")

var angle = 0.0
var dir_vec = Vector2.ZERO
var speed = 0
var height = 35.0
var moving = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	var dir_delta = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir_delta.x += 1
	if Input.is_action_pressed("ui_left"):
		dir_delta.x -= 1
	if Input.is_action_pressed("ui_up"):
		dir_delta.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir_delta.y += 1
	if speed == 0:
		dir_vec = dir_delta
	
	if dir_delta != Vector2.ZERO:
		tween.remove(self, "dir_vec")
		tween.interpolate_property(self, "dir_vec", dir_vec, dir_delta, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()
	
	if dir_delta != Vector2.ZERO && !moving:
		# just started moving
		tween.remove(self, "speed")
		tween.interpolate_property(self, "speed", speed, MAX_SPEED, ACCEL_TIME, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()
		moving = true
	
	if dir_delta == Vector2.ZERO && moving:
		# just stopped moving
		tween.remove(self, "speed")
		tween.interpolate_property(self, "speed", speed, 0, STOP_TIME, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()
		moving = false
	
	angle += dir_vec.x * speed * delta
	height += dir_vec.y * speed * 20.0 * delta
	
	while (angle < 0):
		angle += PI * 2
	while (angle > PI * 2):
		angle -= PI * 2
	
	if height < MIN_HEIGHT:
		height = MIN_HEIGHT
	if height > MAX_HEIGHT:
		height = MAX_HEIGHT
	
	self.translation = Vector3(cos(angle) * distance, height, sin(angle) * distance)
	self.look_at(Vector3(0,0,0), Vector3(0, 1, 0))
