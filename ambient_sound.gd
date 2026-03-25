extends Node3D

@onready var ambient = $AmbientSound
@onready var creepy = $CreepySound

func _ready():
	vary_ambient()
	creepy_loop()

func vary_ambient():
	while true:
		await get_tree().create_timer(randf_range(5, 12)).timeout
		ambient.pitch_scale = randf_range(0.9, 1.1)
		ambient.volume_db = randf_range(-12, -6)

func creepy_loop():
	while true:
		await get_tree().create_timer(randf_range(8, 20)).timeout
		creepy.play()
