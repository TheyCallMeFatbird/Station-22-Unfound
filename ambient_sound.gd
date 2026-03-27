extends Node3D

@onready var ambient = $AmbientSound
@onready var creepy = $CreepySound
@onready var player = $Player  # make sure this path is correct

var creepy_sounds = [
	preload("res://sounds/metal-clang.mp3"),
	preload("res://sounds/metal-clang-2.mp3")
]

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
		play_random_creepy()

func play_random_creepy():
	if creepy_sounds.is_empty():
		return

	# pick random sound
	var sound = creepy_sounds.pick_random()
	creepy.stream = sound

	# variation (VERY important)
	creepy.pitch_scale = randf_range(0.9, 1.1)
	creepy.volume_db = randf_range(-10, -5)

	# 🎯 directional positioning (around player)
	var offset = Vector3(
		randf_range(-6, 6),
		randf_range(0, 2),
		randf_range(-6, 6)
	)

	creepy.global_position = player.global_position + offset

	creepy.play()
