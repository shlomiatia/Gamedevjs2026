class_name HUD
extends HBoxContainer

const ICON_SIZE := Vector2(20, 20)
const NEED_COLOR_LOW  := Color(0.486, 0.071, 0.169)  # #7c122b
const NEED_COLOR_HIGH := Color(0.741, 0.153, 0.035)  # #bd2709

var _coordination_manager: CoordinationManager = null

var _lbl_workers: Label
var _lbl_dead: Label
var _lbl_planks: Label
var _lbl_bricks: Label
var _lbl_food: Label
var _lbl_drink: Label
var _lbl_clothing: Label
var _lbl_tool: Label
var _lbl_pending_planks: Label
var _lbl_pending_bricks: Label

var _need_food_row: HBoxContainer
var _need_drink_row: HBoxContainer
var _need_clothing_row: HBoxContainer
var _need_tool_row: HBoxContainer
var _need_food_icon: TextureRect
var _need_drink_icon: TextureRect
var _need_clothing_icon: TextureRect
var _need_tool_icon: TextureRect
var _need_food_lbl: Label
var _need_drink_lbl: Label
var _need_clothing_lbl: Label
var _need_tool_lbl: Label

var _broken_row: HBoxContainer
var _broken_clothing: Control
var _broken_tool: Control
var _broken_clothing_lbl: Label
var _broken_tool_lbl: Label

func setup(coordination_manager: CoordinationManager) -> void:
	_coordination_manager = coordination_manager

func _ready() -> void:
	# Full viewport width; ALIGNMENT_CENTER keeps the content panel centered
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	grow_vertical = Control.GROW_DIRECTION_END
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Single shrink-to-content child so ALIGNMENT_CENTER has something to center
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(inner)

	# ── Panel ─────────────────────────────────────────────────────────────
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.55)
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", panel_style)
	inner.add_child(panel)

	var pvbox := VBoxContainer.new()
	pvbox.add_theme_constant_override("separation", 4)
	panel.add_child(pvbox)

	# ── Row 1: Workers / Dead ─────────────────────────────────────────────
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 0)
	pvbox.add_child(top_row)

	var worker_tex := AtlasTexture.new()
	worker_tex.atlas = load("res://Textures/worker.png") as Texture2D
	worker_tex.region = Rect2(0, 0, 32, 32)
	_lbl_workers = _icon_label(top_row, worker_tex, " 0/30",
		"Workers: current count / target (%d)" % CoordinationManager.WIN_WORKER_COUNT)
	_gap(top_row, 20)
	_lbl_dead = _icon_label(top_row, load("res://Textures/dead.png"), " 0", "Dead workers")

	# ── Resource grid ─────────────────────────────────────────────────────
	var drink_mat := _make_drink_mat()

	var grid_row := HBoxContainer.new()
	grid_row.add_theme_constant_override("separation", 0)
	grid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pvbox.add_child(grid_row)

	# Planks column
	var planks_col := _make_col(grid_row)
	_lbl_planks = _icon_label(_hrow(planks_col), load("res://Textures/planks.png"), " 0", "Planks available")
	_lbl_pending_planks = _icon_label(_hrow(planks_col), load("res://Textures/house.png"), " 0",
		"Pending building sites needing planks")

	grid_row.add_child(VSeparator.new())

	# Bricks column
	var bricks_col := _make_col(grid_row)
	_lbl_bricks = _icon_label(_hrow(bricks_col), load("res://Textures/brick.png"), " 0", "Bricks available")
	_lbl_pending_bricks = _icon_label(_hrow(bricks_col), load("res://Textures/bricks_house.png"), " 0",
		"Pending building sites needing bricks")

	grid_row.add_child(VSeparator.new())

	# Food column
	var food_col := _make_col(grid_row)
	_lbl_food = _icon_label(_hrow(food_col), load("res://Textures/food.png"), " 0", "Food available")
	var fd := _need_row(food_col, load("res://Textures/food.png"), "Hungry workers (below 50% hunger)")
	_need_food_row = fd[0]; _need_food_icon = fd[1]; _need_food_lbl = fd[2]

	grid_row.add_child(VSeparator.new())

	# Drink column
	var drink_col := _make_col(grid_row)
	_lbl_drink = _icon_label(_hrow(drink_col), load("res://Textures/cider.png"), " 0", "Drink available", drink_mat)
	var dd := _need_row(drink_col, load("res://Textures/cider.png"), "Thirsty workers (below 50% thirst)", drink_mat)
	_need_drink_row = dd[0]; _need_drink_icon = dd[1]; _need_drink_lbl = dd[2]

	grid_row.add_child(VSeparator.new())

	# Clothes column
	var clothes_col := _make_col(grid_row)
	_lbl_clothing = _icon_label(_hrow(clothes_col), load("res://Textures/Clothes.png"), " 0", "Clothing available")
	var cd := _need_row(clothes_col, load("res://Textures/Clothes.png"), "Workers with worn clothing (below 50%)")
	_need_clothing_row = cd[0]; _need_clothing_icon = cd[1]; _need_clothing_lbl = cd[2]

	grid_row.add_child(VSeparator.new())

	# Tools column
	var tools_col := _make_col(grid_row)
	_lbl_tool = _icon_label(_hrow(tools_col), load("res://Textures/tool.png"), " 0", "Tools available")
	var td := _need_row(tools_col, load("res://Textures/tool.png"), "Workers with worn tools (below 50%)")
	_need_tool_row = td[0]; _need_tool_icon = td[1]; _need_tool_lbl = td[2]

	# ── Broken/Unusable row (outside panel) ───────────────────────────────
	_broken_row = HBoxContainer.new()
	_broken_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_broken_row.add_theme_constant_override("separation", 0)
	_broken_row.visible = false
	inner.add_child(_broken_row)

	var bc := _broken_indicator(_broken_row, "Unusable clothing (workers with 0 clothing)")
	_broken_clothing = bc[0]; _broken_clothing_lbl = bc[1]
	_gap(_broken_row, 12)
	var bt := _broken_indicator(_broken_row, "Broken tools (workers with 0 tools)")
	_broken_tool = bt[0]; _broken_tool_lbl = bt[1]

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_col(parent: HBoxContainer) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(col)
	return col

# Creates a centered HBoxContainer row inside a column
func _hrow(col: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	col.add_child(row)
	return row

func _icon_label(parent: Node, texture: Texture2D, initial_text: String,
		tooltip: String = "", mat: Material = null) -> Label:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = ICON_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if mat != null:
		icon.material = mat
	if tooltip != "":
		icon.tooltip_text = tooltip
	parent.add_child(icon)

	var lbl := Label.new()
	lbl.text = initial_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if tooltip != "":
		lbl.tooltip_text = tooltip
	parent.add_child(lbl)
	return lbl

# Need indicator row: always occupies space, transparent when count=0
func _need_row(col: VBoxContainer, texture: Texture2D,
		tooltip: String, mat: Material = null) -> Array:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	row.tooltip_text = tooltip
	row.modulate = Color(1, 1, 1, 0)  # invisible but reserves layout space
	col.add_child(row)

	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = ICON_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if mat != null:
		icon.material = mat
	row.add_child(icon)

	var lbl := Label.new()
	lbl.text = "0"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", NEED_COLOR_LOW)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)

	return [row, icon, lbl]

func _broken_indicator(parent: HBoxContainer, tooltip: String) -> Array:
	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 3)
	outer.tooltip_text = tooltip
	parent.add_child(outer)

	var stack := Control.new()
	stack.custom_minimum_size = ICON_SIZE
	outer.add_child(stack)

	var worker_tex := AtlasTexture.new()
	worker_tex.atlas = load("res://Textures/worker.png") as Texture2D
	worker_tex.region = Rect2(0, 0, 32, 32)
	var worker_icon := TextureRect.new()
	worker_icon.texture = worker_tex
	worker_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	worker_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	worker_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stack.add_child(worker_icon)

	var strike_icon := TextureRect.new()
	strike_icon.texture = load("res://Textures/strike.png") as Texture2D
	strike_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	strike_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	strike_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stack.add_child(strike_icon)

	var lbl := Label.new()
	lbl.text = "0"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	outer.add_child(lbl)

	return [outer, lbl]

func _make_drink_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://Shaders/pallete_swap.gdshader") as Shader
	mat.set_shader_parameter("original_0", Color(0.972549, 0.250980, 0.105882, 1))
	mat.set_shader_parameter("replace_0", Color(0, 0, 0, 0))
	mat.set_shader_parameter("original_1", Color(0.741176, 0.152941, 0.035294, 1))
	mat.set_shader_parameter("replace_1", Color(0, 0, 0, 0))
	mat.set_shader_parameter("original_2", Color(0.486275, 0.070588, 0.168627, 1))
	mat.set_shader_parameter("replace_2", Color(0, 0, 0, 0))
	mat.set_shader_parameter("original_3", Color(0.615686, 0.113725, 0.101961, 1))
	mat.set_shader_parameter("replace_3", Color(0, 0, 0, 0))
	return mat

func _gap(parent: Node, width: int = 10) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(width, 0)
	parent.add_child(spacer)

# ── Process ───────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if _coordination_manager == null:
		return
	_refresh()

func _refresh() -> void:
	var cm := _coordination_manager
	cm.all_workers = cm.all_workers.filter(func(w): return is_instance_valid(w))

	var hungry := 0
	var thirsty := 0
	var worn_clothing := 0
	var worn_tool := 0
	var no_clothing := 0
	var no_tool := 0
	var clothing_half := Constants.initial_clothing / 2.0
	var tool_half := Constants.initial_tool / 2.0

	for entity in cm.all_workers:
		var wn := entity.get_node_or_null("Worker/WorkerNeeds") as WorkerNeeds
		if wn == null:
			continue
		if wn.hunger < Constants.hunger_threshold:
			hungry += 1
		if wn.thirst < Constants.thirst_threshold:
			thirsty += 1
		if wn.clothing < clothing_half:
			worn_clothing += 1
		if wn.get_need_value(Worker.NeedType.TOOL) < tool_half:
			worn_tool += 1
		if wn.clothing == 0.0:
			no_clothing += 1
		if wn.get_need_value(Worker.NeedType.TOOL) == 0.0:
			no_tool += 1

	var R := CoordinationManager.ResourceType
	var res: Dictionary = {}
	for type in R.values():
		var total := 0
		for building in cm.buildings:
			var pile: ResourcePile = building.get_pile_for_type(type)
			if pile != null:
				total += pile.get_child_count()
		res[type] = total

	var site_counts := cm.get_site_count_by_resource()
	var total_workers := cm.all_workers.size()

	_lbl_workers.text = " %d/%d" % [total_workers, CoordinationManager.WIN_WORKER_COUNT]
	_lbl_dead.text = " %d" % cm._dead_count
	_lbl_planks.text = " %d" % res[R.PLANK]
	_lbl_bricks.text = " %d" % res[R.BRICK]
	_lbl_food.text = " %d" % (res[R.APPLE] + res[R.CHEESE] + res[R.BREAD])
	_lbl_drink.text = " %d" % (res[R.CIDER] + res[R.MILK] + res[R.BEER])
	_lbl_clothing.text = " %d" % res[R.CLOTHES]
	_lbl_tool.text = " %d" % res[R.TOOL]
	_lbl_pending_planks.text = " %d" % site_counts[R.PLANK]
	_lbl_pending_bricks.text = " %d" % site_counts[R.BRICK]

	_update_need(_need_food_row, _need_food_icon, _need_food_lbl, hungry, total_workers)
	_update_need(_need_drink_row, _need_drink_icon, _need_drink_lbl, thirsty, total_workers)
	_update_need(_need_clothing_row, _need_clothing_icon, _need_clothing_lbl, worn_clothing, total_workers)
	_update_need(_need_tool_row, _need_tool_icon, _need_tool_lbl, worn_tool, total_workers)

	_update_broken(_broken_clothing, _broken_clothing_lbl, no_clothing)
	_update_broken(_broken_tool, _broken_tool_lbl, no_tool)
	_broken_row.visible = no_clothing > 0 or no_tool > 0

func _update_need(row: HBoxContainer, icon: TextureRect, lbl: Label, count: int, total: int) -> void:
	if count == 0:
		row.modulate = Color(1, 1, 1, 0)
		return
	lbl.text = "%d" % count
	var ratio := clampf(float(count) / float(maxi(total, 1)), 0.0, 1.0)
	var color := NEED_COLOR_LOW.lerp(NEED_COLOR_HIGH, ratio)
	icon.modulate = color
	lbl.add_theme_color_override("font_color", color)
	row.modulate = Color.WHITE

func _update_broken(container: Control, lbl: Label, count: int) -> void:
	container.visible = count > 0
	lbl.text = "%d" % count

# ── Tutorial rect helpers ─────────────────────────────────────────────────────

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
