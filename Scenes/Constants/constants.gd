extends Node

# Movement
var worker_move_speed := 80.0
var sheep_follow_speed := 80.0
var sheep_follow_stop_distance := 16.0

# Hunger
var initial_hunger := 300.0
var hunger_threshold := initial_hunger / 2.0

# Thirst
var initial_thirst := 300.0
var thirst_threshold := initial_thirst / 2.0

# Clothing (blocks worker at 0, no threshold replenishment)
var initial_clothing := 250.0

# Tool (blocks worker at 0, no threshold replenishment)
var initial_tool := 150.0

# Need satisfaction
var need_satisfaction_value := 200.0

# Work durations (ms)
var chop_duration_ms := 5000.0
var pick_duration_ms := 5000.0
var mill_work_duration_ms := 5000.0
var build_duration_ms := 5000.0
var mine_duration_ms := 5000.0
var kiln_work_duration_ms := 5000.0

# Sheep
var sheep_eat_time_ms := 5000.0
var sheep_shear_time_ms := 5000.0
var max_herd_size := 8
var output_pile_capacity := 8

# Tweaking UI infrastructure
var canvas_layer: CanvasLayer
var display_label: Label
var current_property_index: int = 0
var current_category_index: int = 0
var properties: Array = []
var categories: Array = []
var timer = 0
const is_disabled = true

func _ready():
	if is_disabled:
		return

	categories = [
		{
			"name": "Movement",
			"properties": [
				["worker_move_speed", 1],
				["sheep_follow_speed", 1],
				["sheep_follow_stop_distance", 1],
			]
		},
		{
			"name": "Hunger",
			"properties": [
				["initial_hunger", 10],
				["hunger_drain_normal", 0.1],
				["hunger_drain_working", 0.1],
				["hunger_threshold", 10],
				["need_satisfaction_value", 10],
			]
		},
		{
			"name": "Thirst",
			"properties": [
				["initial_thirst", 10],
				["thirst_drain_normal", 0.1],
				["thirst_drain_walking", 0.1],
				["thirst_threshold", 10],
			]
		},
		{
			"name": "Clothing & Tool",
			"properties": [
				["initial_clothing", 10],
				["clothing_drain", 0.1],
				["initial_tool", 10],
				["tool_drain", 0.1],
			]
		},
		{
			"name": "Work Durations",
			"properties": [
				["chop_duration_ms", 100],
				["pick_duration_ms", 100],
				["mill_work_duration_ms", 100],
				["build_duration_ms", 100],
				["mine_duration_ms", 100],
				["kiln_work_duration_ms", 100],
			]
		},
		{
			"name": "Sheep",
			"properties": [
				["sheep_eat_time_ms", 100],
				["sheep_shear_time_ms", 100],
				["max_herd_size", 1],
				["output_pile_capacity", 1],
			]
		},
	]

	properties = categories[current_category_index]["properties"]
	setup_ui()
	update_display()
	print_all_values()


func setup_ui():
	canvas_layer = CanvasLayer.new()
	get_parent().add_child.call_deferred(canvas_layer)
	display_label = Label.new()
	display_label.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	display_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	display_label.grow_vertical = Control.GROW_DIRECTION_END
	display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	display_label.add_theme_constant_override("margin_right", 10)
	display_label.add_theme_constant_override("margin_top", 10)
	canvas_layer.add_child.call_deferred(display_label)
	display_label.visible = false


func _input(event: InputEvent):
	if is_disabled:
		return
	if Input.is_action_just_pressed("ui_text_completion_replace"):
		display_label.visible = !display_label.visible
	if event.is_action_pressed("ui_right"):
		current_property_index = (current_property_index + 1) % properties.size()
		update_display()
	elif event.is_action_pressed("ui_left"):
		current_property_index = (current_property_index - 1) % properties.size()
		if current_property_index < 0:
			current_property_index = properties.size() - 1
		update_display()
	elif event.is_action_pressed("ui_page_up"):
		change_category(1)
	elif event.is_action_pressed("ui_page_down"):
		change_category(-1)
	elif event.is_action_pressed("ui_up"):
		timer = 0
		adjust_current_value(1)
	elif event.is_action_pressed("ui_down"):
		timer = 0
		adjust_current_value(-1)


func change_category(direction: int):
	current_category_index = (current_category_index + direction) % categories.size()
	if current_category_index < 0:
		current_category_index = categories.size() - 1
	properties = categories[current_category_index]["properties"]
	current_property_index = 0
	update_display()


func _process(delta: float) -> void:
	if is_disabled:
		return
	if Input.is_action_pressed("ui_up"):
		timer += delta
		if timer > 0.2:
			adjust_current_value(1)
	elif Input.is_action_pressed("ui_down"):
		timer += delta
		if timer > 0.2:
			adjust_current_value(-1)


func adjust_current_value(direction: float):
	var var_name = properties[current_property_index][0]
	var amt = properties[current_property_index][1]
	var current_num = get(var_name)
	var new_num = current_num + direction * amt
	if amt == 0:
		new_num = 0 if current_num != 0 else 1
	set(var_name, new_num)
	update_display()
	print_all_values()


func update_display():
	var var_name = properties[current_property_index][0]
	var current_value = get(var_name)
	var category_name = categories[current_category_index]["name"]
	var fps = Engine.get_frames_per_second()
	display_label.text = "[%s]\n%s: %.2f\nFPS: %d" % [category_name, var_name, current_value, fps]


func print_all_values():
	print("\nCurrent Values:")
	print("----------------")
	for var_name in properties:
		print("%s: %.2f" % [var_name, get(var_name[0])])
	print("----------------")
