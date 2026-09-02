extends TextureButton

# Botao reutilizavel que concentra layout e comportamento das configuracoes.
const Layout := preload("res://ui/settings/SettingsButtonLayout.gd")


func _ready() -> void:
	apply_standard_layout()
	# A propria instancia abre o menu para evitar callbacks repetidos em cada tela.
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func apply_standard_layout() -> void:
	# Ancoras no fim do viewport mantem tamanho e margem em qualquer resolucao.
	custom_minimum_size = Layout.BUTTON_SIZE
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -Layout.BUTTON_SIZE.x - Layout.SCREEN_MARGIN
	offset_top = -Layout.BUTTON_SIZE.y - Layout.SCREEN_MARGIN
	offset_right = -Layout.SCREEN_MARGIN
	offset_bottom = -Layout.SCREEN_MARGIN
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE


func _on_pressed() -> void:
	SettingsManager.open_menu()
