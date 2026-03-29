extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 9.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.004

# Stamina
@export var max_stamina = 100.0
@export var stamina_drain = 25.0
@export var stamina_regen = 15.0

var stamina = 100.0
var is_sprinting = false
var stamina_depleted = false
var vignette_intensity = 0.0
var hud: CanvasLayer

# Head bob
var bob_timer = 0.0
const BOB_FREQ_WALK = 2.0
const BOB_FREQ_SPRINT = 3.2
const BOB_AMP_Y = 0.08
const BOB_AMP_X = 0.04
var camera_default_y = 1.6

@onready var footsteps = $Footsteps
@export var footstep_interval = 0.45
@export var pitch_range = Vector2(0.9, 1.1)
@export var volume_range_db = Vector2(-8, -4)
var footstep_timer = 0.0

@onready var flashlight = $Flashlight
@onready var flashlight_sound = $FlashlightSound
@onready var camera = $Camera3D

var rotation_x = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	flicker_loop()
	call_deferred("_init_hud")
	

func _init_hud():
	hud = get_tree().get_root().get_node("Node3D/HUD")

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-80), deg_to_rad(80))
		camera.rotation.x = rotation_x

	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("flashlight_toggle"):
		flashlight.visible = !flashlight.visible
		flashlight_sound.play()

func _physics_process(delta):
	handle_stamina(delta)
	handle_movement(delta)
	handle_head_bob(delta)
	update_effects(delta)
	handle_footsteps(delta)

func get_input_direction() -> Vector3:
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	return direction.normalized()

func handle_stamina(delta):
	var wants_sprint = Input.is_action_pressed("sprint")
	var moving = get_input_direction().length() > 0

	is_sprinting = wants_sprint and not stamina_depleted and moving and stamina > 0

	if is_sprinting:
		stamina -= stamina_drain * delta
		stamina = max(stamina, 0.0)
		if stamina == 0.0:
			stamina_depleted = true
	else:
		stamina += stamina_regen * delta
		stamina = min(stamina, max_stamina)
		if stamina_depleted and stamina >= max_stamina:
			stamina_depleted = false

func handle_movement(delta):
	var direction = get_input_direction()
	var current_speed = sprint_speed if is_sprinting else walk_speed

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	move_and_slide()

func update_effects(delta):
	if not hud:
		return
	var stamina_pct = stamina / max_stamina
	vignette_intensity = hud.update_effects(stamina_pct, is_sprinting, delta, vignette_intensity)

func flicker_loop():
	while true:
		await get_tree().create_timer(randf_range(3.0, 8.0)).timeout
		for i in range(randi_range(1, 3)):
			flashlight.light_negative = true
			await get_tree().create_timer(0.03).timeout
			flashlight.light_negative = false
			await get_tree().create_timer(0.03).timeout

func handle_head_bob(delta):
	var moving = get_input_direction().length() > 0

	if moving and is_on_floor():
		var freq = BOB_FREQ_SPRINT if is_sprinting else BOB_FREQ_WALK
		bob_timer += delta * freq
	else:
		bob_timer = lerp(bob_timer, 0.0, delta * 6.0)

	camera.position.y = camera_default_y + sin(bob_timer * 2.0) * BOB_AMP_Y
	camera.position.x = cos(bob_timer) * BOB_AMP_X

func handle_footsteps(delta):
	if get_input_direction().length() > 0 and is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0:
			play_footstep()
			footstep_timer = footstep_interval / (1.5 if is_sprinting else 1.0)
	else:
		footstep_timer = 0.0

func play_footstep():
	footsteps.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	footsteps.volume_db = randf_range(volume_range_db.x, volume_range_db.y)
	var length = footsteps.stream.get_length()
	if length > 0:
		footsteps.seek(randf_range(0, length * 0.5))
	footsteps.play()
