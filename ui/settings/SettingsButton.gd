extends TextureButton

# Botao reutilizavel que permanece fixo no canto superior direito em qualquer resolucao.
const BUTTON_SIZE := Vector2(84.0, 84.0)
const SCREEN_MARGIN := 18.0


func _ready() -> void:
	apply_standard_layout()
	# Recalcula as margens quando a janela ou o canvas Web muda de tamanho.
	if not get_viewport().size_changed.is_connected(apply_standard_layout):
		get_viewport().size_changed.connect(apply_standard_layout)


func apply_standard_layout() -> void:
	# Usa coordenadas do viewport em vez de uma posicao fixa da cena de origem.
	var viewport_size := get_viewport_rect().size
	custom_minimum_size = BUTTON_SIZE
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = viewport_size.x - BUTTON_SIZE.x - SCREEN_MARGIN
	offset_top = SCREEN_MARGIN
	offset_right = viewport_size.x - SCREEN_MARGIN
	offset_bottom = BUTTON_SIZE.y + SCREEN_MARGIN
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
