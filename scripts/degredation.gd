extends Area3D

@export var pixelation_speed := 0.5  # how fast it degrades
@export var min_scale := 0.05        # how pixelated it gets

var active := false
var current_scale := 1.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" and not active:
		active = true

func _process(delta):
	if not active:
		return

	current_scale -= pixelation_speed * delta
	current_scale = max(current_scale, min_scale)

	# THIS is the key: lowers 3D resolution scale
	get_viewport().scaling_3d_scale = current_scale

	if current_scale <= min_scale:
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()
