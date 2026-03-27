extends CharacterBody3D

@export var speed = 5.0
@export var mouse_sensitivity = 0.002
@onready var flashlight = $Flashlight
var rotation_x = 0.0
@onready var flashlight_sound = $FlashlightSound

@onready var camera = $Camera3D

func _ready():
	if speed == null:
		speed = 5.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-80), deg_to_rad(80))
		camera.rotation.x = rotation_x
	if event.is_action_pressed("flashlight_toggle"):
		flashlight.visible = !flashlight.visible
		flashlight_sound.play()

func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()

func flicker_loop():
	while true:
		await get_tree().create_timer(randf_range(3.0, 8.0)).timeout
		
		# tiny rapid flicker burst
		for i in range(randi_range(1, 3)):
			flashlight.light_negative = true
			await get_tree().create_timer(0.03).timeout
			
			flashlight.light_negative = false
			await get_tree().create_timer(0.03).timeout
