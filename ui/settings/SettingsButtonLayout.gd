extends RefCounted

# Fonte unica das dimensoes do botao e da faixa que o conteudo deve respeitar.
const BUTTON_SIZE := Vector2(84.0, 84.0)
const SCREEN_MARGIN := 24.0
const CONTENT_SAFE_MARGIN := BUTTON_SIZE.x + SCREEN_MARGIN * 2.0
const CENTERED_CONTENT_HORIZONTAL_CLEARANCE := CONTENT_SAFE_MARGIN * 2.0


static func fit_centered_content_width(viewport_width: float, desired_width: float) -> float:
	# Limita paineis centralizados antes da faixa protegida do botao, dos dois lados.
	return minf(desired_width, maxf(0.0, viewport_width - CENTERED_CONTENT_HORIZONTAL_CLEARANCE))
