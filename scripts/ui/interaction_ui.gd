class_name InteractionUI
extends CanvasLayer

@onready var crosshair: ColorRect = $CenterContainer/Crosshair
@onready var prompt_label: Label = $PromptLabel
@onready var notification_label: Label = $NotificationLabel
@onready var hud_container: Control = $HUDContainer
@onready var stamina_container: MarginContainer = $HUDContainer/StaminaContainer
@onready var stamina_bar: ProgressBar = $HUDContainer/StaminaContainer/StaminaBar
@onready var battery_container: MarginContainer = $HUDContainer/BatteryContainer
@onready var battery_bar: ProgressBar = $HUDContainer/BatteryContainer/HBox/BatteryBar
@onready var battery_percent: Label = $HUDContainer/BatteryContainer/HBox/BatteryPercent

var _notification_timer: Timer

# HUD fade & states
var _stamina_level: float = 100.0
var _stamina_max: float = 100.0
var _is_exhausted: bool = false
var _stamina_alpha: float = 0.0

var _battery_level: float = 100.0
var _battery_max: float = 100.0
var _flashlight_active: bool = false
var _battery_alpha: float = 0.0
var _battery_reveal_timer: float = 0.0

func _ready() -> void:
	prompt_label.text = ""
	prompt_label.visible = false
	
	notification_label.text = ""
	notification_label.visible = false
	
	_notification_timer = Timer.new()
	_notification_timer.one_shot = true
	_notification_timer.timeout.connect(_on_notification_timeout)
	add_child(_notification_timer)
	
	if stamina_container:
		stamina_container.modulate.a = 0.0
	if battery_container:
		battery_container.modulate.a = 0.0

func _process(delta: float) -> void:
	_update_stamina_display(delta)
	_update_battery_display(delta)

func _update_stamina_display(delta: float) -> void:
	if not stamina_container or not stamina_bar:
		return
	
	# Only visible when stamina is depleted/draining or player is exhausted
	var target_alpha = 0.0
	if _stamina_level < (_stamina_max - 1.0) or _is_exhausted:
		target_alpha = 0.85
	
	_stamina_alpha = move_toward(_stamina_alpha, target_alpha, 3.5 * delta)
	stamina_container.modulate.a = _stamina_alpha
	
	# Modulate color if exhausted
	if _is_exhausted:
		stamina_bar.modulate = Color(0.95, 0.28, 0.25, 1.0)
	else:
		stamina_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _update_battery_display(delta: float) -> void:
	if not battery_container or not battery_bar or not battery_percent:
		return
	
	if _battery_reveal_timer > 0.0:
		_battery_reveal_timer -= delta
	
	var is_low = _battery_level <= 20.0
	var should_show = _flashlight_active or is_low or (_battery_reveal_timer > 0.0)
	var target_alpha = 0.85 if should_show else 0.0
	
	_battery_alpha = move_toward(_battery_alpha, target_alpha, 3.0 * delta)
	battery_container.modulate.a = _battery_alpha
	
	# Low battery visual warning pulse
	if is_low and _flashlight_active:
		var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
		battery_bar.modulate = lerp(Color(0.95, 0.35, 0.2), Color(0.5, 0.15, 0.1), pulse)
	else:
		battery_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)

func update_stamina(current: float, max_val: float, is_exhausted: bool = false) -> void:
	_stamina_level = current
	_stamina_max = max_val
	_is_exhausted = is_exhausted
	if stamina_bar:
		stamina_bar.max_value = max_val
		stamina_bar.value = current

func update_battery(current: float, max_val: float) -> void:
	_battery_level = current
	_battery_max = max_val
	if battery_bar:
		battery_bar.max_value = max_val
		battery_bar.value = current
	if battery_percent:
		battery_percent.text = "%d%%" % int(clamp((current / max(1.0, max_val)) * 100.0, 0.0, 100.0))
	# Reveal indicator for a few seconds on update (e.g. pickup or change)
	_battery_reveal_timer = 2.5

func set_flashlight_active(is_on: bool) -> void:
	_flashlight_active = is_on

func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

func hide_prompt() -> void:
	prompt_label.text = ""
	prompt_label.visible = false

func show_notification(text: String, duration: float = 3.0) -> void:
	notification_label.text = text
	notification_label.visible = true
	_notification_timer.start(duration)

func _on_notification_timeout() -> void:
	notification_label.text = ""
	notification_label.visible = false
