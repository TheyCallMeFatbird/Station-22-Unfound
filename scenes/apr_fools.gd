extends RigidBody3D

func _ready():
	var num = 22
	randomize()
	var roll = randi() % 10000 + 1
	if not (num == roll):
		queue_free()
