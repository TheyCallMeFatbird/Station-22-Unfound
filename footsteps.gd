extends CharacterBody3D  # or Node3D if you’re using custom movement

# ----------------------
# NODES
# ----------------------
@onready var footsteps = $Footsteps  # AudioStreamPlayer3D node
@onready var camera = $Camera3D      # for reference if needed

# ----------------------
# FOOTSTEP SETTINGS
# ----------------------
# Single audio file containing two steps
@export var footstep_file: AudioStream = preload("res://sounds/metal-footsteps.mp3")

# Timing between steps in seconds (you can tweak based on movement speed)
@export var footstep_interval = 0.45

# Pitch/volume variation
@export var pitch_range = Vector2(0.9, 1.1)   # min/max
@export var volume_range_db = Vector2(-8, -4) # min/max

# ----------------------
# MOVEMENT VARIABLES
# ----------------------
@export var speed = 5.0
#var velocity = Vector3.ZERO
var direction = Vector3.ZERO

# ----------------------
# INTERNAL
# ----------------------
var footstep_timer = 0.0

func _ready():
	footsteps.stream = footstep_file
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	handle_input()
	handle_movement(delta)
	handle_footsteps(delta)

# ----------------------
# INPUT
# ----------------------
func handle_input():
	direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("move_backward"):
		direction.z += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	direction = direction.normalized()

# ----------------------
# MOVEMENT
# ----------------------
func handle_movement(_delta):
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

# ----------------------
# FOOTSTEPS
# ----------------------
func handle_footsteps(delta):
	# Only tick timer if moving on floor
	if direction.length() > 0 and is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0:
			play_footstep()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0  # reset timer when stopped

func play_footstep():
	# Slight variation
	footsteps.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	footsteps.volume_db = randf_range(volume_range_db.x, volume_range_db.y)
	
	# Optional: slight random offset into the clip (for multiple steps inside one file)
	var length = footsteps.stream.get_length()
	if length > 0:
		footsteps.seek(randf_range(0, length * 0.5)) # jump into first half

	footsteps.play()
