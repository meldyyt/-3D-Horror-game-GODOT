extends Node

signal loop_started(loop_number: int, loop_data: Resource)
signal loop_completed(loop_number: int)
signal custom_event_triggered(event_id: String)

@export var current_loop: int = 1
@export var loop_data_resources: Array[Resource] = []

var _is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_default_loops()

func _load_default_loops() -> void:
	if loop_data_resources.is_empty():
		for i in range(1, 6):
			var path = "res://resources/loops/loop_0%d.tres" % i
			if ResourceLoader.exists(path):
				var res = load(path)
				if res:
					loop_data_resources.append(res)

func get_current_loop_data() -> Resource:
	for data in loop_data_resources:
		if data and data.get("loop_number") == current_loop:
			return data
	if not loop_data_resources.is_empty():
		return loop_data_resources[min(current_loop - 1, loop_data_resources.size() - 1)]
	return null

func advance_loop() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	loop_completed.emit(current_loop)
	current_loop += 1
	
	var data = get_current_loop_data()
	apply_loop_data(data)
	loop_started.emit(current_loop, data)
	_is_transitioning = false

func set_loop(number: int) -> void:
	current_loop = max(1, number)
	var data = get_current_loop_data()
	apply_loop_data(data)
	loop_started.emit(current_loop, data)

func restart_loops() -> void:
	set_loop(1)

func apply_loop_data(data: Resource) -> void:
	if data == null:
		return
	
	var loop_num = data.get("loop_number")
	var loop_title = data.get("loop_title")
	print("[LoopManager] Применение цикла #%s: «%s»" % [str(loop_num), str(loop_title)])
	
	# 1. Audio ambient
	var amb = data.get("ambient_stream") as AudioStream
	if amb:
		var vol = data.get("ambient_volume_db")
		AudioManager.play_ambient(amb, 2.0, vol if vol != null else -6.0)
	
	# 2. Sound cue
	var cue = data.get("sound_cue") as AudioStream
	if cue:
		AudioManager.play_sfx(cue, -4.0)
	
	# 3. Environment & Lighting
	var tree = get_tree()
	if tree == null:
		return
	
	# Update WorldEnvironment fog
	var world_env = tree.get_first_node_in_group("world_environment") as WorldEnvironment
	if world_env and world_env.environment:
		var env = world_env.environment
		var fog_dens = data.get("fog_density")
		if fog_dens != null:
			env.fog_density = fog_dens
		var fog_col = data.get("fog_color")
		if fog_col != null:
			env.fog_light_color = fog_col
	
	# Update corridor lights intensity
	var lights = tree.get_nodes_in_group("corridor_lights")
	var mult = data.get("light_energy_multiplier")
	if mult == null:
		mult = 1.0
	for light in lights:
		if light is Light3D:
			if light.has_meta("original_energy"):
				var orig = light.get_meta("original_energy")
				light.light_energy = orig * mult
			else:
				light.set_meta("original_energy", light.light_energy)
				light.light_energy *= mult
	
	# 4. Show groups
	var show_grps = data.get("show_groups")
	if show_grps:
		for group_name in show_grps:
			var nodes = tree.get_nodes_in_group(group_name)
			for node in nodes:
				if node is Node3D:
					node.visible = true
					node.process_mode = Node.PROCESS_MODE_INHERIT
	
	# 5. Hide groups
	var hide_grps = data.get("hide_groups")
	if hide_grps:
		for group_name in hide_grps:
			var nodes = tree.get_nodes_in_group(group_name)
			for node in nodes:
				if node is Node3D:
					node.visible = false
					node.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 6. Doors control
	_apply_doors_control(data)
	
	# 7. Player notification
	var notif = data.get("notification_text")
	if notif and not str(notif).is_empty():
		var player = tree.get_first_node_in_group("player")
		if player and player.has_method("show_notification"):
			player.show_notification(str(notif), 5.0)
	
	# 8. Custom scripted event
	var ev_id = data.get("custom_event_id")
	if ev_id and not str(ev_id).is_empty():
		custom_event_triggered.emit(str(ev_id))

func _apply_doors_control(data: Resource) -> void:
	var tree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	
	var open_doors = data.get("open_door_names")
	if open_doors:
		for door_name in open_doors:
			var door = tree.current_scene.find_child(door_name, true, false)
			if door and door.has_method("open"):
				door.open()
	
	var close_doors = data.get("close_door_names")
	if close_doors:
		for door_name in close_doors:
			var door = tree.current_scene.find_child(door_name, true, false)
			if door and door.has_method("close"):
				door.close()
	
	var lock_doors = data.get("lock_door_names")
	if lock_doors:
		for door_name in lock_doors:
			var door = tree.current_scene.find_child(door_name, true, false)
			if door and door.has_method("lock"):
				door.lock()
