class_name HUD
extends PanelContainer

const UPDATE_INTERVAL := 0.5
const ICON_SIZE := Vector2(20, 20)

var _coordination_manager: CoordinationManager = null
var _timer := 0.0

var _lbl_workers: Label
var _lbl_planks: Label
var _lbl_bricks: Label
var _lbl_food: Label
var _lbl_drink: Label
var _lbl_clothing: Label
var _lbl_tool: Label

func setup(coordination_manager: CoordinationManager) -> void:
	_coordination_manager = coordination_manager

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	grow_vertical = Control.GROW_DIRECTION_END

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	var row1 := _make_row()
	var row2 := _make_row()
	vbox.add_child(row1)
	vbox.add_child(row2)

	var worker_tex := AtlasTexture.new()
	worker_tex.atlas = load("res://Textures/worker.png") as Texture2D
	worker_tex.region = Rect2(0, 0, 32, 32)

	_lbl_workers = _icon_label(row1, worker_tex, " 0")
	_gap(row1)
	_lbl_planks = _icon_label(row1, load("res://Textures/planks.png"), ": 0/0")
	_gap(row1)
	_lbl_bricks = _icon_label(row1, load("res://Textures/brick.png"), ": 0/0")

	_lbl_food     = _icon_label(row2, load("res://Textures/apple.png"),   ": 0/0")
	_gap(row2)
	_lbl_drink    = _icon_label(row2, load("res://Textures/cider.png"),   ": 0/0")
	_gap(row2)
	_lbl_clothing = _icon_label(row2, load("res://Textures/Clothes.png"), ": 0/0")
	_gap(row2)
	_lbl_tool     = _icon_label(row2, load("res://Textures/tool.png"),    ": 0/0")

func _make_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	return row

func _icon_label(parent: HBoxContainer, texture: Texture2D, initial_text: String) -> Label:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = ICON_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent.add_child(icon)
	var lbl := Label.new()
	lbl.text = initial_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(lbl)
	return lbl

func get_workers_rect() -> Rect2:
	var r := _lbl_workers.get_global_rect()
	r.position.x -= ICON_SIZE.x + 2.0
	r.size.x += ICON_SIZE.x + 2.0
	return r

func get_planks_rect() -> Rect2:
	var r := _lbl_planks.get_global_rect()
	r.position.x -= ICON_SIZE.x + 2.0
	r.size.x += ICON_SIZE.x + 2.0
	return r

func get_food_drink_rect() -> Rect2:
	var rf := _lbl_food.get_global_rect()
	rf.position.x -= ICON_SIZE.x + 2.0
	rf.size.x += ICON_SIZE.x + 2.0
	var rd := _lbl_drink.get_global_rect()
	rd.position.x -= ICON_SIZE.x + 2.0
	rd.size.x += ICON_SIZE.x + 2.0
	return rf.merge(rd)

func get_clothing_tool_rect() -> Rect2:
	var rc := _lbl_clothing.get_global_rect()
	rc.position.x -= ICON_SIZE.x + 2.0
	rc.size.x += ICON_SIZE.x + 2.0
	var rt := _lbl_tool.get_global_rect()
	rt.position.x -= ICON_SIZE.x + 2.0
	rt.size.x += ICON_SIZE.x + 2.0
	return rc.merge(rt)

func _gap(parent: HBoxContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(14, 0)
	parent.add_child(spacer)

func _process(delta: float) -> void:
	if _coordination_manager == null:
		return
	_timer += delta
	if _timer < UPDATE_INTERVAL:
		return
	_timer = 0.0
	_refresh()

func _refresh() -> void:
	var s := _coordination_manager.get_hud_stats()
	var res: Dictionary = s.resources
	var R := CoordinationManager.ResourceType

	_lbl_workers.text = " %d / %d" % [s.live_workers, CoordinationManager.WIN_WORKER_COUNT]
	_lbl_planks.text  = ": %d/%d" % [res[R.PLANK], s.plank_sites]
	_lbl_bricks.text  = ": %d/%d" % [res[R.BRICK], s.brick_sites]
	_lbl_food.text     = ": %d/%d" % [res[R.APPLE],   s.hungry]
	_lbl_drink.text    = ": %d/%d" % [res[R.CIDER],   s.thirsty]
	_lbl_clothing.text = ": %d/%d" % [res[R.CLOTHES], s.no_clothing]
	_lbl_tool.text     = ": %d/%d" % [res[R.TOOL],    s.no_tool]
