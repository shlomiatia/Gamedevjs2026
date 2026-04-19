class_name BuildingTooltip
extends CanvasLayer

# Integer keys match CoordinationManager.ResourceType enum order:
# LOG=0, PLANK=1, APPLE=2, CIDER=3, WOOL=4, CLOTHES=5, CLAY=6, BRICK=7,
# COAL=8, IRON_ORE=9, IRON_BAR=10, TOOL=11
const _ICON_TEXTURE := {
	0: preload("res://Textures/Log.png"),
	1: preload("res://Textures/planks.png"),
	2: preload("res://Textures/apple.png"),
	3: preload("res://Textures/cider.png"),
	4: preload("res://Textures/Wool.png"),
	5: preload("res://Textures/Clothes.png"),
	6: preload("res://Textures/ore.png"),
	7: preload("res://Textures/brick.png"),
	8: preload("res://Textures/ore.png"),
	9: preload("res://Textures/ore.png"),
	10: preload("res://Textures/brick.png"),
	11: preload("res://Textures/tool.png"),
}

# Modulate to distinguish resources that share the same base texture
const _ICON_MODULATE := {
	6: Color(0.85, 0.58, 0.32),  # CLAY — warm brown over ore.png
	8: Color(0.15, 0.09, 0.18),  # COAL — near-black over ore.png
}

var _panel: PanelContainer
var _margin: MarginContainer
var _vbox: VBoxContainer
var _name_label: Label
var _cost_row: HBoxContainer
var _action_row: HBoxContainer

func _ready() -> void:
	layer = 100
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_margin = MarginContainer.new()
	_panel.add_child(_margin)

	_vbox = VBoxContainer.new()
	_margin.add_child(_vbox)

	_name_label = Label.new()
	_vbox.add_child(_name_label)

	_cost_row = HBoxContainer.new()
	_vbox.add_child(_cost_row)

	_action_row = HBoxContainer.new()
	_vbox.add_child(_action_row)

	_panel.visible = false

func show_tooltip(data: Dictionary, show_cost: bool = true) -> void:
	_populate(data, show_cost)
	_panel.visible = true

func hide_tooltip() -> void:
	_panel.visible = false

func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var mouse := get_viewport().get_mouse_position()
	var vp_size := get_viewport().get_visible_rect().size
	var sz := _panel.get_minimum_size()
	_panel.position = Vector2(
		clamp(mouse.x + 12.0, 0.0, vp_size.x - sz.x),
		clamp(mouse.y - sz.y - 8.0, 0.0, vp_size.y - sz.y)
	)

func _populate(data: Dictionary, show_cost: bool) -> void:
	var font_size := 14 if show_cost else 11
	var icon_size := 20 if show_cost else 14
	var pad := 8 if show_cost else 5
	var pad_v := 6 if show_cost else 4
	var sep := 4 if show_cost else 2

	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad_v)
	_margin.add_theme_constant_override("margin_bottom", pad_v)
	_vbox.add_theme_constant_override("separation", sep)

	_name_label.text = data["display_name"]
	_name_label.add_theme_font_size_override("font_size", font_size)

	for c in _cost_row.get_children():
		c.queue_free()
	_cost_row.visible = show_cost
	_cost_row.add_theme_constant_override("separation", sep)
	if show_cost:
		if data["cost"] < 0:
			_add_label(_cost_row, "Cost: Free", font_size)
		else:
			_add_label(_cost_row, "Cost: ", font_size)
			_add_icon(_cost_row, data["cost"], icon_size)

	for c in _action_row.get_children():
		c.queue_free()
	_action_row.add_theme_constant_override("separation", sep)
	match data["action"]:
		"produce":
			_add_label(_action_row, "Produces ", font_size)
			_add_icon(_action_row, data["output"], icon_size)
		"convert":
			_add_label(_action_row, "Converts ", font_size)
			for i in data["inputs"].size():
				if i > 0:
					_add_label(_action_row, " + ", font_size)
				_add_icon(_action_row, data["inputs"][i], icon_size)
			_add_label(_action_row, " to ", font_size)
			_add_icon(_action_row, data["output"], icon_size)
		"train":
			_add_label(_action_row, "Build buildings", font_size)

func _add_label(parent: HBoxContainer, text: String, font_size: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	parent.add_child(lbl)

func _add_icon(parent: HBoxContainer, resource_type: int, icon_size: int) -> void:
	var tex_rect := TextureRect.new()
	tex_rect.texture = _ICON_TEXTURE.get(resource_type)
	tex_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _ICON_MODULATE.has(resource_type):
		tex_rect.modulate = _ICON_MODULATE[resource_type]
	parent.add_child(tex_rect)
