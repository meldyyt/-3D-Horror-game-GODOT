extends Node

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENT: StringName = &"Ambient"
const BUS_UI: StringName = &"UI"

var _ambient_player: AudioStreamPlayer
var _ambient_tween: Tween
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ambient Player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)
	
	# SFX Player Pool
	for i in range(_sfx_pool_size):
		var p = AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

func play_ambient(stream: AudioStream, fade_duration: float = 1.5, volume_db: float = -4.0) -> void:
	if stream == null:
		return
	
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	
	if _ambient_player.playing:
		_ambient_tween = create_tween()
		_ambient_tween.tween_property(_ambient_player, "volume_db", -40.0, fade_duration * 0.5)
		_ambient_tween.tween_callback(func():
			_ambient_player.stream = stream
			_ambient_player.play()
		)
		_ambient_tween.tween_property(_ambient_player, "volume_db", volume_db, fade_duration * 0.5)
	else:
		_ambient_player.stream = stream
		_ambient_player.volume_db = -40.0
		_ambient_player.play()
		_ambient_tween = create_tween()
		_ambient_tween.tween_property(_ambient_player, "volume_db", volume_db, fade_duration)

func stop_ambient(fade_duration: float = 1.5) -> void:
	if not _ambient_player.playing:
		return
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient_player, "volume_db", -40.0, fade_duration)
	_ambient_tween.tween_callback(_ambient_player.stop)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.bus = BUS_SFX
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch_scale
			player.play()
			return
	var fallback = _sfx_players[0]
	fallback.stream = stream
	fallback.volume_db = volume_db
	fallback.pitch_scale = pitch_scale
	fallback.play()

func play_ui(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.bus = BUS_UI
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = 1.0
			player.play()
			return

func play_sfx_3d(stream: AudioStream, global_pos: Vector3, parent: Node = null, max_distance: float = 15.0, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	if stream == null:
		return null
	var player3d = AudioStreamPlayer3D.new()
	player3d.bus = BUS_SFX
	player3d.stream = stream
	player3d.volume_db = volume_db
	player3d.max_distance = max_distance
	if parent:
		parent.add_child(player3d)
	else:
		var scene = get_tree().current_scene
		if scene:
			scene.add_child(player3d)
		else:
			add_child(player3d)
	player3d.global_position = global_pos
	player3d.play()
	player3d.finished.connect(player3d.queue_free)
	return player3d

func set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear_volume, 0.0, 1.0)))

func get_bus_volume(bus_name: StringName) -> float:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(idx))
	return 1.0
