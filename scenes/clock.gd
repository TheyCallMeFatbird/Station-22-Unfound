extends Label3D

var elapsed = 0.0
const MAX_TIME = 6 * 60.0

var glitching = false

func _process(delta):
	if glitching:
		return

	elapsed += delta
	if elapsed >= MAX_TIME:
		_glitch_reset()
		return

	_update_display(elapsed)

func _update_display(t: float):
	var mins = int(t / 60) % 60
	var secs = int(t) % 60
	text = "%02d:%02d" % [mins, secs]

func _glitch_reset():
	glitching = true
	_do_glitch()

func _do_glitch():
	var glitch_chars = ["#", "%", "@", "!", "?", "/", "\\", "|"]
	for i in range(12):
		await get_tree().create_timer(0.05).timeout
		text = "%s%s:%s%s" % [
			glitch_chars.pick_random(),
			glitch_chars.pick_random(),
			glitch_chars.pick_random(),
			glitch_chars.pick_random()
		]
	elapsed = 0.0
	text = "00:00"
	glitching = false
