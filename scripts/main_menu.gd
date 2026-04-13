extends CanvasLayer

@onready var content_vbox = $ContentVBox
@onready var play_btn = $ContentVBox/PlayBtn
@onready var credits_btn = $ContentVBox/CreditsBtn
@onready var quit_btn = $ContentVBox/QuitBtn
@onready var credits_overlay = $CreditsOverlay
@onready var credits_back_btn = $CreditsOverlay/CreditsVBox/CreditsBackBtn

var crunching := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_viewport().scaling_3d_scale = 1.0
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	play_btn.pressed.connect(_on_play)
	quit_btn.pressed.connect(func(): get_tree().quit())
	credits_btn.pressed.connect(_on_credits)

func _on_play():
	if crunching:
		return
	crunching = true

	var tween = create_tween().set_parallel(false)

	tween.tween_property(content_vbox, "modulate:a", 0.0, 0.35)

	# re-enable viewport stretch — this is what causes the crunch visually
	tween.tween_callback(func():
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	)

	tween.tween_method(
		func(v: float): get_viewport().scaling_3d_scale = v,
		1.0, 0.08, 0.9
	)

	tween.tween_interval(0.2)

	tween.tween_callback(func():
		get_viewport().scaling_3d_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)

func _on_credits():
	credits_overlay.visible = !credits_overlay.visible
