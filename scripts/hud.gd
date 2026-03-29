extends CanvasLayer

@onready var vignette: ColorRect = $Vignette
@onready var stamina_bar: TextureProgressBar = $StaminaBar

func _ready():
	stamina_bar.modulate.a = 0.0
	_build_bar_texture()

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

	# Bar visibility
	var target_alpha = 0.0 if stamina_pct > 0.99 and not is_sprinting else 1.0
	stamina_bar.modulate.a = lerp(stamina_bar.modulate.a, target_alpha, delta * 4.0)
	stamina_bar.value = stamina_pct * 100.0
	# no color changes, stays blue

	return vignette_intensity
