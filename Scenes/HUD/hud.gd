class_name HUD
extends HBoxContainer

const ICON_SIZE := Vector2(20, 20)
const NEED_COLOR_LOW := Color("f22f46")
const NEED_COLOR_HIGH := Color("f22f46")

var _coordination_manager: CoordinationManager = null

# Workers row
@onready var _lbl_workers: Label = $Content/Panel/VBox/GridRow/PlanksCol/WorkersRow/WorkersLabel
@onready var _row_dead: HBoxContainer = $Content/Panel/VBox/GridRow/FoodCol/DeadRow
@onready var _lbl_dead: Label = $Content/Panel/VBox/GridRow/FoodCol/DeadRow/DeadLabel

# Resource counts
@onready var _lbl_planks: Label = $Content/Panel/VBox/GridRow/PlanksCol/PlanksTopRow/PlanksLabel
@onready var _lbl_bricks: Label = $Content/Panel/VBox/GridRow/BricksCol/BricksTopRow/BricksLabel
@onready var _lbl_food: Label = $Content/Panel/VBox/GridRow/FoodCol/FoodTopRow/FoodLabel
@onready var _lbl_drink: Label = $Content/Panel/VBox/GridRow/DrinkCol/DrinkTopRow/DrinkLabel
@onready var _lbl_clothing: Label = $Content/Panel/VBox/GridRow/ClothesCol/ClothesTopRow/ClothesLabel
@onready var _lbl_tool: Label = $Content/Panel/VBox/GridRow/ToolsCol/ToolsTopRow/ToolsLabel

# Pending building sites
@onready var _lbl_pending_planks: Label = $Content/Panel/VBox/GridRow/PlanksCol/PlanksBotRow/PendingPlanksLabel
@onready var _lbl_pending_bricks: Label = $Content/Panel/VBox/GridRow/BricksCol/BricksBotRow/PendingBricksLabel

# Drink shader icons (material applied at runtime)
@onready var _drink_icon: TextureRect = $Content/Panel/VBox/GridRow/DrinkCol/DrinkTopRow/DrinkIcon
@onready var _drink_need_icon: TextureRect = $Content/Panel/VBox/GridRow/DrinkCol/DrinkNeedRow/DrinkNeedIcon

# Need indicator rows + icons + labels
@onready var _need_food_row: HBoxContainer = $Content/Panel/VBox/GridRow/FoodCol/FoodNeedRow
@onready var _need_food_icon: TextureRect = $Content/Panel/VBox/GridRow/FoodCol/FoodNeedRow/FoodNeedIcon
@onready var _need_food_lbl: Label = $Content/Panel/VBox/GridRow/FoodCol/FoodNeedRow/FoodNeedLabel

@onready var _need_drink_row: HBoxContainer = $Content/Panel/VBox/GridRow/DrinkCol/DrinkNeedRow
@onready var _need_drink_icon: TextureRect = $Content/Panel/VBox/GridRow/DrinkCol/DrinkNeedRow/DrinkNeedIcon
@onready var _need_drink_lbl: Label = $Content/Panel/VBox/GridRow/DrinkCol/DrinkNeedRow/DrinkNeedLabel

@onready var _need_clothing_row: HBoxContainer = $Content/Panel/VBox/GridRow/ClothesCol/ClothesNeedRow
@onready var _need_clothing_icon: TextureRect = $Content/Panel/VBox/GridRow/ClothesCol/ClothesNeedRow/ClothesNeedIcon
@onready var _need_clothing_lbl: Label = $Content/Panel/VBox/GridRow/ClothesCol/ClothesNeedRow/ClothesNeedLabel

@onready var _need_tool_row: HBoxContainer = $Content/Panel/VBox/GridRow/ToolsCol/ToolsNeedRow
@onready var _need_tool_icon: TextureRect = $Content/Panel/VBox/GridRow/ToolsCol/ToolsNeedRow/ToolsNeedIcon
@onready var _need_tool_lbl: Label = $Content/Panel/VBox/GridRow/ToolsCol/ToolsNeedRow/ToolsNeedLabel

# Broken / unusable rows (inside clothing/tools columns)
@onready var _broken_clothing_row: HBoxContainer = $Content/Panel/VBox/GridRow/ClothesCol/ClothesBrokenRow
@onready var _broken_clothing_lbl: Label = $Content/Panel/VBox/GridRow/ClothesCol/ClothesBrokenRow/BrokenClothingLabel
@onready var _broken_tool_row: HBoxContainer = $Content/Panel/VBox/GridRow/ToolsCol/ToolsBrokenRow
@onready var _broken_tool_lbl: Label = $Content/Panel/VBox/GridRow/ToolsCol/ToolsBrokenRow/BrokenToolLabel

func setup(coordination_manager: CoordinationManager) -> void:
    _coordination_manager = coordination_manager

func _ready() -> void:
    var drink_mat := _make_drink_mat()
    _drink_icon.material = drink_mat

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

    for entity in cm.all_workers:
        var wn := entity.get_node_or_null("Worker/WorkerNeeds") as WorkerNeeds
        if wn == null:
            continue
        if wn.hunger < Constants.hunger_threshold:
            hungry += 1
        if wn.thirst < Constants.thirst_threshold:
            thirsty += 1
        if wn.clothing < Constants.clothing_threshold && wn.clothing > 0.0:
            worn_clothing += 1
        var tool_val := wn.get_need_value(Worker.NeedType.TOOL)
        if tool_val < Constants.tool_threshold && tool_val > 0.0:
            worn_tool += 1
        if wn.clothing == 0.0:
            no_clothing += 1
        if tool_val == 0.0:
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
    if cm._dead_count > 0:
        _row_dead.show()
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

    _update_broken(_broken_clothing_row, _broken_clothing_lbl, no_clothing)
    _update_broken(_broken_tool_row, _broken_tool_lbl, no_tool)

func _update_need(row: HBoxContainer, icon: TextureRect, lbl: Label, count: int, total: int) -> void:
    if count == 0:
        row.modulate = Color(1, 1, 1, 0)
        return
    lbl.text = " %d" % count
    var ratio := clampf(float(count) / float(maxi(total, 1)), 0.0, 1.0)
    var color := NEED_COLOR_LOW.lerp(NEED_COLOR_HIGH, ratio)
    icon.modulate = color
    lbl.add_theme_color_override("font_color", color)
    row.modulate = Color.WHITE

func _update_broken(row: HBoxContainer, lbl: Label, count: int) -> void:
    if count == 0:
        row.modulate = Color(1, 1, 1, 0)
        return
    lbl.text = " %d" % count
    row.modulate = Color.WHITE

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
