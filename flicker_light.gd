extends OmniLight3D

var base_energy

func _ready():
	base_energy = light_energy
	flicker_loop()

func flicker_loop():
	while true:
		await get_tree().create_timer(randf_range(2.0, 6.0)).timeout
		
		# quick flicker burst
		for i in range(randi_range(2, 5)):
			light_energy = base_energy * randf_range(0.2, 0.6)
			await get_tree().create_timer(0.05).timeout
			
			light_energy = base_energy
			await get_tree().create_timer(0.05).timeout
