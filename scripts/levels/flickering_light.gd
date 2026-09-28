class_name FlickeringLight
extends OmniLight3D

@export var is_flickering: bool = true
@export var normal_energy: float = 1.0
@export var min_interval: float = 1.0
@export var max_interval: float = 4.0
@export var buzz_sound: AudioStream = preload("res://assets/audio/flicker_buzz.wav")

@export var emissive_mesh: MeshInstance3D

var _timer: float = 0.0
var _next_interval: float = 2.0
var _is_flickering_now: bool = false
var _audio: AudioStreamPlayer3D

func _ready() -> void:
	light_energy = normal_energy
	_next_interval = randf_range(min_interval, max_interval)
	
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 12.0
	_audio.stream = buzz_sound
	add_child(_audio)

func _process(delta: float) -> void:
	if not is_flickering or _is_flickering_now:
		return
	
	_timer += delta
	if _timer >= _next_interval:
		_timer = 0.0
		_next_interval = randf_range(min_interval, max_interval)
		_perform_flicker()

func _perform_flicker() -> void:
	_is_flickering_now = true
	
	if _audio and buzz_sound and randf() < 0.7:
		_audio.pitch_scale = randf_range(0.9, 1.1)
		_audio.volume_db = randf_range(-14.0, -8.0)
		_audio.play()
	
	var tween = create_tween()
	var flicker_count = randi_range(2, 5)
	
	for i in range(flicker_count):
		var dark_energy = randf_range(0.0, normal_energy * 0.25)
		tween.tween_property(self, "light_energy", dark_energy, 0.04)
		tween.tween_callback(func(): _update_emissive(dark_energy / normal_energy))
		tween.tween_property(self, "light_energy", normal_energy, 0.05)
		tween.tween_callback(func(): _update_emissive(1.0))
	
	tween.finished.connect(func():
		light_energy = normal_energy
		_update_emissive(1.0)
		_is_flickering_now = false
	)

func _update_emissive(ratio: float) -> void:
	if emissive_mesh and emissive_mesh.get_active_material(0) is StandardMaterial3D:
		var mat = emissive_mesh.get_active_material(0) as StandardMaterial3D
		mat.emission_energy_multiplier = ratio * 2.0

func force_flicker() -> void:
	if not _is_flickering_now:
		_perform_flicker()

func turn_off() -> void:
	is_flickering = false
	light_energy = 0.0
	visible = false
	_update_emissive(0.0)

func turn_on() -> void:
	visible = true
	light_energy = normal_energy
	_update_emissive(1.0)
