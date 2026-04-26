class_name Worker
extends Node2D

@export var stream: AudioStream

signal died

enum NeedType {FOOD = 0, DRINK = 1, CLOTHING = 2, TOOL = 3}
const NO_NEED := -1

var _navigator: WorkerNavigator = null
var _needs: WorkerNeeds = null
var _backpack: WorkerBackpack = null
var _anim: AnimatedSprite2D = null
var _anim_with_tools: AnimatedSprite2D = null
var _anim_no_tools: AnimatedSprite2D = null
var _working := false
var _anim_working := false
var display_name: String = ""
var building_name: String = ""

# Per-worker appearance state
var _shirt_colors: Array = []
var _skin_colors: Array = []
var _hair_colors: Array = []
var _eye_color := Color.BLACK
var _pants_colors: Array = []
var _clothes_unusable := false
var _tool_blocked := false

const _HAIR_PALETTES: Array = [
	[Color("#ffffff"), Color("#eaeae8"), Color("#cecac9"), Color("#abafb9"), Color("#a18897"), Color("#756270")],
	[Color("#dbcfb1"), Color("#a9a48d"), Color("#7b8382"), Color("#5f5f6e")],
	[Color("#2e2d2b"), Color("#f87b1b"), Color("#f8401b"), Color("#bd2709"), Color("#7c122b")],
	[Color("#ffe08b"), Color("#fac05a"), Color("#eb8f48"), Color("#d17441"), Color("#c75239"), Color("#b12935")],
	[Color("#fdbd8f"), Color("#f0886b"), Color("#d36853"), Color("#ae454a"), Color("#8c3132"), Color("#542323")],
	[Color("#a85848"), Color("#83404c"), Color("#67314b"), Color("#3f2323")],
	[Color("#d49577"), Color("#9f705a"), Color("#845750"), Color("#633b3f")],
]
const _SKIN_PALETTES: Array = [
	[Color("#fdbd8f"), Color("#f0886b"), Color("#d36853"), Color("#ae454a"), Color("#8c3132"), Color("#542323")],
]
const _EYE_COLORS: Array = [Color("#3f2323"), Color("#315dcd"), Color("#0b5931")]
const _PANTS_DEFAULT: Array = [Color("#668faf"), Color("#585d81"), Color("#45365d")]
const _PANTS_CLOTHES: Array = [Color("#eaeae8"), Color("#cecac9"), Color("#abafb9")]
const _PANTS_FLAX: Array = [Color("#f6bafe"), Color("#d59ff4"), Color("#b070eb")]

func setup(home: Node2D, map: Map, coordination_manager: Node) -> void:
	_navigator = $WorkerNavigator
	_needs = $WorkerNeeds
	_backpack = $WorkerBackpack
	_anim_with_tools = $AnimatedSprite2D
	_anim = _anim_with_tools
	building_name = str(home.get("BUILDING_NAME")) if home.get("BUILDING_NAME") != null else ""
	_navigator.setup(get_parent(), home, map, $NavigationAgent2D)
	_needs.setup(get_parent(), map, coordination_manager, _navigator)
	_backpack.setup(get_parent())
	coordination_manager.register_worker(get_parent())
	_needs.died.connect(func():
		var cause := "starvation" if _needs.hunger <= 0.0 else "dehydration"
		(coordination_manager as CoordinationManager).notify_worker_died(display_name, cause)
		coordination_manager.deregister_worker(get_parent())
		(home.get_node("Building") as BuildingComponent).on_worker_died()
		died.emit()
		var grave := Sprite2D.new()
		grave.texture = load("res://Textures/grave.png") as Texture2D
		grave.offset = Vector2(0, -grave.texture.get_height() / 2.0)
		var worker_pos: Vector2 = get_parent().global_position
		var world := get_parent().get_parent()
		get_parent().queue_free()
		grave.global_position = worker_pos
		world.add_child(grave)
	)
	_needs.needs_satisfied.connect(func(): get_parent().resume_work())
	_pants_colors = _PANTS_DEFAULT.duplicate()
	_choose_random_appearance()
	_apply_building_colors(home)
	_setup_no_tools_sprite()
	_refresh_material()
	$AudioStreamPlayer2D.stream = stream

func _choose_random_appearance() -> void:
	var hair_palette: Array = _HAIR_PALETTES[randi() % _HAIR_PALETTES.size()]
	var hair_start: int = randi() % maxi(1, hair_palette.size() - 2)
	_hair_colors = [hair_palette[hair_start], hair_palette[hair_start + 1], hair_palette[hair_start + 2]]

	var skin_palette: Array = _SKIN_PALETTES[randi() % _SKIN_PALETTES.size()]
	var skin_start: int = randi() % maxi(1, skin_palette.size() - 2)
	_skin_colors = [skin_palette[skin_start], skin_palette[skin_start + 1], skin_palette[skin_start + 2]]

	_eye_color = _EYE_COLORS[randi() % _EYE_COLORS.size()]

func _apply_building_colors(home: Node2D) -> void:
	var sprite := home.get_node_or_null("Building/Sprite2D") as Sprite2D
	if sprite == null:
		return
	var building_mat := sprite.material as ShaderMaterial
	if building_mat == null:
		return
	var r0 = building_mat.get_shader_parameter("replace_0")
	if r0 == null:
		return
	_shirt_colors = [
		r0,
		building_mat.get_shader_parameter("replace_1"),
		building_mat.get_shader_parameter("replace_2"),
	]
	var worker_mat := _anim.material.duplicate() as ShaderMaterial
	_anim.material = worker_mat

func _setup_no_tools_sprite() -> void:
	var tex := load("res://Textures/worker without tools.png") as Texture2D
	var mk := func(x: int, y: int) -> AtlasTexture:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(x, y, 32, 64)
		return at
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anim_defs := [
		["down_stand", 5.0, [[0, 0], [32, 0]]],
		["down_walk", 8.0, [[96, 0], [0, 0], [128, 0], [0, 0]]],
		["down_work", 4.0, [[64, 0], [32, 0]]],
		["side_stand", 5.0, [[0, 128], [32, 128]]],
		["side_walk", 8.0, [[96, 128], [0, 128], [128, 128], [0, 128]]],
		["side_work", 4.0, [[64, 128], [32, 128]]],
		["up_stand", 5.0, [[0, 64], [32, 64]]],
		["up_walk", 8.0, [[96, 64], [0, 64], [128, 64], [0, 64]]],
		["up_work", 4.0, [[64, 64], [32, 64]]],
	]
	for def in anim_defs:
		sf.add_animation(def[0])
		sf.set_animation_speed(def[0], def[1])
		sf.set_animation_loop(def[0], true)
		for coords in def[2]:
			sf.add_frame(def[0], mk.call(coords[0], coords[1]))
	_anim_no_tools = AnimatedSprite2D.new()
	_anim_no_tools.position = _anim_with_tools.position
	_anim_no_tools.sprite_frames = sf
	_anim_no_tools.material = _anim_with_tools.material
	_anim_no_tools.visible = false
	add_child(_anim_no_tools)

func _refresh_material() -> void:
	var mat := _anim.material as ShaderMaterial
	if mat == null:
		return
	var shirt: Array = _skin_colors if _clothes_unusable else _shirt_colors
	if shirt.size() >= 3:
		mat.set_shader_parameter("replace_0", shirt[0])
		mat.set_shader_parameter("replace_1", shirt[1])
		mat.set_shader_parameter("replace_2", shirt[2])
	if _hair_colors.size() >= 3:
		mat.set_shader_parameter("replace_3", _hair_colors[0])
		mat.set_shader_parameter("replace_4", _hair_colors[1])
		mat.set_shader_parameter("replace_5", _hair_colors[2])
	if _skin_colors.size() >= 3:
		mat.set_shader_parameter("replace_6", _skin_colors[0])
		mat.set_shader_parameter("replace_7", _skin_colors[1])
		mat.set_shader_parameter("replace_8", _skin_colors[2])
	mat.set_shader_parameter("replace_9", _eye_color)
	if _pants_colors.size() >= 3:
		mat.set_shader_parameter("replace_10", _pants_colors[0])
		mat.set_shader_parameter("replace_11", _pants_colors[1])
		mat.set_shader_parameter("replace_12", _pants_colors[2])

func on_tool_blocked() -> void:
	if _tool_blocked:
		return
	_tool_blocked = true
	_anim_no_tools.visible = true
	_anim_with_tools.visible = false
	_anim = _anim_no_tools
	_anim.play(_anim_with_tools.animation)
	_anim.flip_h = _anim_with_tools.flip_h

func on_tool_restored() -> void:
	if not _tool_blocked:
		return
	_tool_blocked = false
	_anim_with_tools.visible = true
	_anim_no_tools.visible = false
	_anim = _anim_with_tools
	_anim.play(_anim_no_tools.animation)
	_anim.flip_h = _anim_no_tools.flip_h

func on_clothes_blocked() -> void:
	if _clothes_unusable:
		return
	_clothes_unusable = true
	_refresh_material()

func on_clothes_received(resource_type: int) -> void:
	if resource_type == CoordinationManager.ResourceType.FLAX_CLOTHES:
		_pants_colors = _PANTS_FLAX.duplicate()
	else:
		_pants_colors = _PANTS_CLOTHES.duplicate()
	_clothes_unusable = false
	_refresh_material()

func navigate_to(world_pos: Vector2) -> void:
	_navigator.navigate_to(world_pos)

func tick_movement(delta: float) -> bool:
	return _navigator.tick(delta)

func home_world_pos() -> Vector2:
	return _navigator.home_world_pos()

func is_satisfying_need() -> bool:
	return _needs.is_satisfying_need()

func handle_need(need: int, pile: ResourcePile, resource_type: int) -> void:
	_needs.handle_need(need, pile, resource_type)

func get_need_value(need: int) -> float:
	return _needs.get_need_value(need)

func set_working(val: bool) -> void:
	_working = val
	_needs.set_working(val)

func set_anim_working(val: bool) -> void:
	_anim_working = val

func set_uses_tools(val: bool) -> void:
	_needs.uses_tools = val

func _process(_delta: float) -> void:
	if _navigator == null or _anim == null:
		return
	if is_satisfying_need() || !_working:
		var tween = create_tween()
		tween.tween_property($AudioStreamPlayer2D, "volume_db", -80.0, 1.0)
		tween.tween_callback($AudioStreamPlayer2D.stop)
		tween.tween_property($AudioStreamPlayer2D, "volume_db", 0.0, 0)
	elif _working && !$AudioStreamPlayer2D.is_playing():
		$AudioStreamPlayer2D.play()
	var facing := _navigator.get_facing()
	var prefix: String
	var flip := false
	if abs(facing.x) > abs(facing.y):
		prefix = "side"
		flip = facing.x < 0
	elif facing.y < 0:
		prefix = "up"
	else:
		prefix = "down"
	var suffix := "work" if ((_working or _anim_working) and not _needs.is_satisfying_need()) else ("walk" if _navigator.is_moving() && !_needs.is_waiting_for_need() else "stand")
	var anim_name := prefix + "_" + suffix
	if _anim.animation != anim_name:
		_anim.play(anim_name)
	_anim.flip_h = flip
	_backpack.update(prefix)

func carry(resource: Node2D) -> void:
	_backpack.carry(resource)

func carry_from_pile(pile: ResourcePile) -> void:
	_backpack.carry_from_pile(pile, get_parent())

func drop() -> Node2D:
	return _backpack.drop()

func is_carrying() -> bool:
	return _backpack.is_carrying()

func is_output_full(pile: ResourcePile) -> bool:
	var cap := pile.capacity if pile.capacity > 0 else Constants.output_pile_capacity
	return pile.get_child_count() >= cap
