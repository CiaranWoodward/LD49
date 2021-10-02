extends Camera

export var MAX_HEIGHT : float = 125.0
export var MIN_HEIGHT : float = 10.0
export var distance : float = 120.0
export var MAX_SPEED = 10.0
export var ACCEL_TIME = 0.5
export var STOP_TIME = 0.2
export var ZOOM_AMOUNT = 0.5
export var ZOOM_TIME = 0.2
export var ZOOM_MIN = 1.0
export var ZOOM_MAX = 4.0

onready var tween = get_node("Tween")

var angle = 0.0
var dir_vec = Vector2.ZERO
var speed = 0
var height = 35.0
var moving = false
var dragging = false
var rezoom = false
var zoom = 1.0
var target_zoom = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(event):
	# Only allow unhandled input for start drag
	if event is InputEventMouseButton and (event.button_index == BUTTON_RIGHT || event.button_index == BUTTON_MIDDLE):
		if event.is_pressed():
			dragging = true
			tween.remove(self, "dir_vec")
			tween.remove(self, "speed")
			speed = 0
			moving = false
			dir_vec = Vector2.ZERO
	if event.is_action_pressed("zoom_in"):
		target_zoom += ZOOM_AMOUNT
		#rezoom = true # Disabled zooming, it felt a bit janky
	if event.is_action_pressed("zoom_out"):
		target_zoom -= ZOOM_AMOUNT
		#rezoom = true

func _input(event):
	# Once we have started dragging, always track the input
	if not dragging:
		return
	if event is InputEventMouseButton and (event.button_index == BUTTON_RIGHT || event.button_index == BUTTON_MIDDLE):
		if not event.is_pressed():
			dragging = false
	if dragging && event is InputEventMouseMotion:
		angle += event.relative.x / (250.0 * zoom)
		height += event.relative.y / 2.0
		_bound_level()

func _bound_level():
	while (angle < 0):
		angle += PI * 2
	while (angle > PI * 2):
		angle -= PI * 2
	if height < MIN_HEIGHT:
		height = MIN_HEIGHT
	if height > MAX_HEIGHT:
		height = MAX_HEIGHT
	
	var camdist = distance - (distance * (zoom - ZOOM_MIN) / (ZOOM_MAX * 2))
	self.translation = Vector3(cos(angle) * camdist, height, sin(angle) * camdist)
	var lookatpoint = Vector3(cos(angle) * distance * (zoom - ZOOM_MIN) / (ZOOM_MAX * 2), 0, sin(angle) * distance * (zoom - ZOOM_MIN) / (ZOOM_MAX * 2))
	self.look_at(lookatpoint, Vector3(0, 1, 0))

func _process(delta: float) -> void:
	if rezoom:
		if target_zoom > ZOOM_MAX:
			target_zoom = ZOOM_MAX
		if target_zoom < ZOOM_MIN:
			target_zoom = ZOOM_MIN
		if target_zoom != zoom:
			tween.remove(self, "zoom")
			tween.interpolate_property(self, "zoom", zoom, target_zoom, ZOOM_TIME, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			tween.start()
		rezoom = false
	
	if dragging:
		_bound_level()
		return
	
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
	
	_bound_level()
