extends CanvasLayer

@onready var vignette: ColorRect = $Vignette

@onready var blur_overlay: ColorRect = $BlurOverlay
@onready var stamina_bar: TextureProgressBar = $StaminaBar

@onready var note_prompt = $NotePrompt
@onready var note_input: LineEdit = $NotePrompt/ClipboardBG/NoteInput
@onready var note_timestamp: Label = $NotePrompt/ClipboardBG/Timestamp
@onready var journal_panel = $JournalPanel
@onready var journal_list: VBoxContainer = $JournalPanel/Panel/ScrollContainer/VBox

@onready var anomaly_picker = $AnomalyPicker
@onready var btn_light = $AnomalyPicker/ButtonRow/BtnLight
@onready var btn_moved = $AnomalyPicker/ButtonRow/BtnMoved
@onready var btn_sound = $AnomalyPicker/ButtonRow/BtnSound
@onready var btn_missing = $AnomalyPicker/ButtonRow/BtnMissing
@onready var btn_visual = $AnomalyPicker/ButtonRow/BtnVisual
@onready var btn_doc = $AnomalyPicker/ButtonRow/BtnDoc
var clipboard_mesh: Sprite3D = null

var panic_pulse_time = 0.0
var panic_pulse_cooldown = 0.0
var clipboard_text: Label3D = null
func _ready():
	stamina_bar.modulate.a = 0.0
	blur_overlay.modulate.a = 0.0
	_build_bar_texture()
	
	btn_light.pressed.connect(_on_anomaly_selected.bind("LIGHT ANOMALY — irregular illumination behavior observed."))
	btn_moved.pressed.connect(_on_anomaly_selected.bind("DISPLACEMENT — object not in expected position."))
	btn_sound.pressed.connect(_on_anomaly_selected.bind("AUDIO ANOMALY — sound from unexpected source or location."))
	btn_missing.pressed.connect(_on_anomaly_selected.bind("ABSENCE — object or fixture unaccounted for."))
	btn_visual.pressed.connect(_on_anomaly_selected.bind("VISUAL ANOMALY — unexplained phenomenon observed."))
	btn_doc.pressed.connect(_on_anomaly_selected.bind("DOCUMENTATION — record appears altered or misplaced."))
	var player = get_tree().get_root().get_node_or_null("Node3D/Player")
	if player:
		clipboard_mesh = player.get_node_or_null("Camera3D/Clipboard")
	if clipboard_mesh:
		clipboard_text = clipboard_mesh.get_node_or_null("ClipboardText")

func _on_anomaly_selected(text: String):
	note_input.text = text
	note_input.grab_focus()
	note_input.caret_column = text.length()
	if clipboard_text:
		clipboard_text.text = text

func _build_bar_texture():
	var w = 50
	var h = int(stamina_bar.custom_minimum_size.y)
	if h <= 0:
		h = 4

	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var half = h / 2
	for y in range(h):
		var col = Color(0.0, 0.688, 0.682, 1.0) if y < half else Color(0.0, 0.545, 0.552, 1.0)
		for x in range(w):
			img.set_pixel(x, y, col)
	stamina_bar.texture_progress = ImageTexture.create_from_image(img)

	var bg_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	bg_img.fill(Color(0.1, 0.1, 0.1, 0.6))
	stamina_bar.texture_under = ImageTexture.create_from_image(bg_img)

func update_effects(stamina_pct: float, is_sprinting: bool, delta: float, vignette_intensity: float) -> float:
	# Vignette
	var low = stamina_pct < 0.35
	var target_vignette = 1.0 if low else 0.0
	vignette_intensity = lerp(vignette_intensity, target_vignette, delta * 3.0)
	vignette.material.set_shader_parameter("intensity", vignette_intensity)

	# Panic vision pulse (visual-only scare cue)
	panic_pulse_cooldown = max(panic_pulse_cooldown - delta, 0.0)
	if low and is_sprinting and panic_pulse_cooldown <= 0.0 and panic_pulse_time <= 0.0 and randf() < 0.09:
		panic_pulse_time = randf_range(0.08, 0.16)
		panic_pulse_cooldown = randf_range(0.8, 1.8)

	if panic_pulse_time > 0.0:
		panic_pulse_time = max(panic_pulse_time - delta, 0.0)
		blur_overlay.modulate.a = lerp(blur_overlay.modulate.a, 0.16, delta * 18.0)
	else:
		blur_overlay.modulate.a = lerp(blur_overlay.modulate.a, 0.0, delta * 10.0)

	# Bar visibility
	var target_alpha = 0.0 if stamina_pct > 0.99 and not is_sprinting else 1.0
	stamina_bar.modulate.a = lerp(stamina_bar.modulate.a, target_alpha, delta * 4.0)
	stamina_bar.value = stamina_pct * 100.0
	# no color changes, stays blue

	return vignette_intensity

var journal_open := false
var prompt_open := false

func open_note_prompt():
	if prompt_open or journal_open:
		return
	if clipboard_mesh:
		clipboard_mesh.visible = true
	prompt_open = true
	#note_prompt.visible = true
	anomaly_picker.visible = true
	note_input.text = ""
	var clock = get_tree().get_root().get_node_or_null("Node3D/Label3D")
	note_timestamp.text = clock.text if clock else "??:??"
	note_input.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_player_locked(true)

func _on_note_confirmed(text: String):
	if text.strip_edges() == "":
		close_note_prompt()
		return
	Observe.add_entry(text.strip_edges(), note_timestamp.text)
	close_note_prompt()

func close_note_prompt():
	if clipboard_mesh:
		clipboard_mesh.visible = false
	prompt_open = false
	#note_prompt.visible = false
	anomaly_picker.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_set_player_locked(false)
	var player = get_tree().get_root().get_node_or_null("Node3D/Player")
	if player:
		player.slowdown_timer = player.POST_OBSERVE_SLOWDOWN

func _set_player_locked(state: bool):
	var player = get_tree().get_root().get_node_or_null("Node3D/Player")
	if player:
		player.movement_locked = state

func toggle_journal():
	journal_open = !journal_open
	journal_panel.visible = journal_open
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if journal_open else Input.MOUSE_MODE_CAPTURED
	)
	if journal_open:
		_refresh_journal()

func _refresh_journal():
	for child in journal_list.get_children():
		child.queue_free()
	for entry in Observe.entries:
		var label = Label.new()
		label.text = "[%s] %s" % [entry["time"], entry["note"]]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_font_override("font", load("res://fonts/Share_Tech_Mono/ShareTechMono-Regular.ttf"))
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
		journal_list.add_child(label)


func _on_line_edit_text_submitted(new_text: String) -> void:
	pass # Replace with function body.
