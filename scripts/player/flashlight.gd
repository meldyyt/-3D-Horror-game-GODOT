class_name Flashlight
extends SpotLight3D

signal state_changed(is_on: bool)
signal flicker_started()
signal flicker_finished()
signal battery_changed(current: float, max_val: float)
signal battery_depleted()

@export var is_on: bool = false
@export var is_enabled: bool = true
@export var click_sound: AudioStream = preload("res://assets/audio/flashlight_click.wav")
@export var flicker_sound: AudioStream = preload("res://assets/audio/flicker_buzz.wav")

@export_group("Light Settings")
@export var normal_energy: float = 1.6

@export_group("Battery")
@export var max_battery: float = 100.0
@export var battery: float = 100.0
@export var drain_rate: float = 1.25 # ~80 seconds of full charge
@export var low_battery_threshold: float = 20.0

var _is_flickering: bool = false
var _low_battery_flicker_timer: float = 0.0

func _ready() -> void:
	visible = is_on and is_enabled
	light_energy = normal_energy if visible else 0.0

func _process(delta: float) -> void:
	if is_on and is_enabled:
		battery = max(0.0, battery - drain_rate * delta)
		battery_changed.emit(battery, max_battery)
		
		if battery <= 0.0:
			battery = 0.0
			is_on = false
			visible = false
			light_energy = 0.0
			_play_click()
			state_changed.emit(false)
			battery_depleted.emit()
		elif battery <= low_battery_threshold:
			# Occasional low battery flicker
			_low_battery_flicker_timer += delta
			if _low_battery_flicker_timer >= randf_range(2.0, 5.0):
				_low_battery_flicker_timer = 0.0
				trigger_flicker(0.6, 0.1)
			elif not _is_flickering:
				var dim_factor = 0.4 + 0.6 * (battery / low_battery_threshold)
				light_energy = normal_energy * dim_factor

func add_battery(amount: float) -> void:
	battery = min(max_battery, battery + amount)
	battery_changed.emit(battery, max_battery)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight"):
		toggle()

func toggle() -> void:
	if not is_enabled:
		_play_click()
		return
	
	is_on = not is_on
	visible = is_on
	light_energy = normal_energy if is_on else 0.0
	_play_click()
	state_changed.emit(is_on)

func turn_on() -> void:
	if not is_enabled:
		return
	if not is_on:
		toggle()

func turn_off() -> void:
	if is_on:
		toggle()

# Horror Event Controls
func force_disable(disable: bool = true) -> void:
	is_enabled = not disable
	if not is_enabled and is_on:
		is_on = false
		visible = false
		light_energy = 0.0
		_play_click()
		state_changed.emit(false)

func force_enable() -> void:
	force_disable(false)

func trigger_flicker(duration: float = 2.0, min_intensity: float = 0.0) -> void:
	if not is_on or not is_enabled or _is_flickering:
		return
	_is_flickering = true
	flicker_started.emit()
	
	if flicker_sound:
		AudioManager.play_sfx(flicker_sound, -6.0)
	
	var tween = create_tween()
	var steps = int(duration * 10)
	for i in range(steps):
		var target_val = normal_energy if (i % 2 == 0) else randf_range(min_intensity, normal_energy * 0.35)
		var step_time = duration / float(steps)
		tween.tween_property(self, "light_energy", target_val, step_time)
	
	tween.tween_property(self, "light_energy", normal_energy, 0.1)
	tween.finished.connect(func():
		_is_flickering = false
		light_energy = normal_energy
		flicker_finished.emit()
	)

func _play_click() -> void:
	if click_sound:
		AudioManager.play_sfx(click_sound, -2.0)
