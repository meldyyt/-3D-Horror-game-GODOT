class_name TestLevel
extends Node3D

@onready var player: Player = $Player
@onready var door_side: Door = get_node_or_null("Doors/SideDoor")
@onready var door_47: Door = get_node_or_null("Doors/Door47")

func _ready() -> void:
	print("--- КВАРТИРА 47: TestLevel v0.3 (Loop System) загружен ---")
	
	if door_47:
		door_47.door_opened.connect(_on_door_47_opened)
	
	if LoopManager:
		LoopManager.loop_started.connect(_on_loop_started)
		# Initialize Loop 1 baseline
		LoopManager.set_loop(1)
		
	_setup_events()

func _setup_events() -> void:
	print("[TestLevel] Настройка хоррор-событий (V0.4)...")
	
	# Создаем событие для Петли 2 (силуэт в коридоре)
	var event_trigger = EventTrigger.new()
	event_trigger.required_loop = 2
	event_trigger.trigger_once = true
	event_trigger.transform.origin = Vector3(0, 1, 0) # Середина коридора
	
	# Добавляем зону срабатывания (коллизию)
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(4, 3, 2)
	event_trigger.add_child(shape)
	
	var seq = EventSequence.new()
	event_trigger.target_event = seq
	
	# 1. Вызвать блинк лампы
	var lamp = get_node_or_null("Lighting/CorridorLamp2")
	if lamp and lamp.has_method("force_flicker"):
		var act_flicker = EventMethodCall.new()
		act_flicker.target_node = lamp
		act_flicker.method_name = "force_flicker"
		seq.add_child(act_flicker)
		
	# 2. Пауза 0.5с
	var wait1 = EventDelay.new()
	wait1.delay_time = 0.5
	seq.add_child(wait1)
	
	# 3. Плач или звук
	var weep = get_node_or_null("LoopEntities/WeepingAudio")
	if weep:
		var act_sound = EventAudio.new()
		act_sound.audio_player = weep
		seq.add_child(act_sound)
		
	# 4. Пауза 1с
	var wait2 = EventDelay.new()
	wait2.delay_time = 1.0
	seq.add_child(wait2)
	
	# 5. Показать силуэт
	var sil = get_node_or_null("LoopEntities/Silhouette")
	if sil:
		var act_show = EventMethodCall.new()
		act_show.target_node = sil
		act_show.method_name = "show"
		seq.add_child(act_show)
		
	event_trigger.add_child(seq)
	add_child(event_trigger)


func _on_loop_started(loop_number: int, loop_data: Resource) -> void:
	print("[TestLevel] Запущен цикл #%d" % loop_number)
	var title = str(loop_data.get("loop_title")) if loop_data else ""
	if player:
		player.show_notification("ЦИКЛ %02d: %s" % [loop_number, title], 5.0)


func _on_door_47_opened() -> void:
	if player:
		player.show_notification("Квартира 47 открыта! Сделайте шаг вперёд, чтобы завершить цикл...", 5.0)
