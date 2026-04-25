class_name MessageSystem
extends VBoxContainer

const MESSAGE_WIDTH := 320.0
const MESSAGE_DISPLAY_TIME := 6.0
const SLIDE_DURATION := 0.3
const FADE_DURATION := 0.8

var _audio_message: AudioStreamPlayer
var _audio_bell: AudioStreamPlayer
var _audio_alert: AudioStreamPlayer

func _ready() -> void:
	position = Vector2(8.0, 8.0)
	custom_minimum_size.x = MESSAGE_WIDTH
	add_theme_constant_override("separation", 4)

	var audio_root := Node.new()
	add_child(audio_root)

	_audio_message = AudioStreamPlayer.new()
	_audio_message.stream = load("res://Audio/message.mp3")
	audio_root.add_child(_audio_message)

	_audio_bell = AudioStreamPlayer.new()
	_audio_bell.stream = load("res://Audio/bell.mp3")
	audio_root.add_child(_audio_bell)

	_audio_alert = AudioStreamPlayer.new()
	_audio_alert.stream = load("res://Audio/alert.mp3")
	audio_root.add_child(_audio_alert)

func setup(coordination_manager: CoordinationManager) -> void:
	coordination_manager.worker_became_hungry.connect(func():
		show_message("A worker is hungry.", "message")
	)
	coordination_manager.worker_became_thirsty.connect(func():
		show_message("A worker is thirsty.", "message")
	)
	coordination_manager.worker_clothes_worn.connect(func():
		show_message("Worker clothes are worn.", "message")
	)
	coordination_manager.worker_tool_worn.connect(func():
		show_message("Worker tools are worn.", "message")
	)
	coordination_manager.worker_died.connect(func(worker_name: String, cause: String):
		show_message(worker_name + " has died due to " + cause + ".", "bell")
	)
	coordination_manager.worker_tool_broken.connect(func(worker_name: String):
		show_message(worker_name + " can't work due to broken tool!", "alert")
	)
	coordination_manager.worker_clothes_unusable.connect(func(worker_name: String):
		show_message(worker_name + " can't work due to unusable clothes!", "alert")
	)

func show_message(text: String, sound_type: String = "") -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	match sound_type:
		"bell":
			style.bg_color = Color(0.25, 0.04, 0.04, 0.4)
		"alert":
			style.bg_color = Color(0.30, 0.13, 0.0, 0.4)
		_:
			style.bg_color = Color(0.04, 0.04, 0.06, 0.4)
	style.content_margin_left = 10.0
	style.content_margin_top = 5.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 5.0
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.label_settings = preload("res://Themes/label_small.tres")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = MESSAGE_WIDTH - 20.0
	panel.add_child(label)

	panel.pivot_offset = Vector2.ZERO
	panel.scale = Vector2(0.0, 1.0)
	panel.modulate.a = 0.0

	add_child(panel)
	move_child(panel, 0)

	var tween := panel.create_tween()
	tween.tween_property(panel, "scale:x", 1.0, SLIDE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, SLIDE_DURATION)
	tween.tween_interval(MESSAGE_DISPLAY_TIME)
	tween.tween_property(panel, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(panel.queue_free)

	match sound_type:
		"message": _audio_message.play()
		"bell": _audio_bell.play()
		"alert": _audio_alert.play()
