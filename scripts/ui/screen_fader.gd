extends CanvasLayer

signal faded_out()
signal faded_in()

@onready var color_rect: ColorRect = $ColorRect

var _tween: Tween

func _ready() -> void:
	layer = 100 # On top of everything
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out(duration: float = 0.4) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", 1.0, duration)
	_tween.finished.connect(func(): faded_out.emit())

func fade_in(duration: float = 0.4) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", 0.0, duration)
	_tween.finished.connect(func(): faded_in.emit())

func blink(hold_duration: float = 0.15, fade_duration: float = 0.35, callback_midpoint: Callable = Callable()) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", 1.0, 0.15)
	if callback_midpoint.is_valid():
		_tween.tween_callback(callback_midpoint)
	if hold_duration > 0.0:
		_tween.tween_interval(hold_duration)
	_tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
