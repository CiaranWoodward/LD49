extends PathFollow

export var crystalSpeed : float = 20

func _ready():
	self.unit_offset = randf()
	self.crystalSpeed *= rand_range(0.9, 1.3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_offset(get_offset() + crystalSpeed * delta)
