extends Spatial

var damage = 0
var target = null
var speed = 30
var offset = Vector3(0, 2, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dir : Vector3 = (target.translation + offset - self.translation)
	var dist = dir.length()
	dir = dir.normalized()
	var to_dist = speed * delta
	if to_dist > 1:
		to_dist = 1
	self.translation += dir * to_dist
	if self.translation.distance_to(target.translation + offset) < 1:
		target.damage(damage)
		queue_free()
