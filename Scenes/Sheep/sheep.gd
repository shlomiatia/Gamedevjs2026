class_name Sheep
extends Node2D

var is_sheared := false
var _is_walking := false
var _is_eating := false
var _follow_delay := 0.0
var _nav_elapsed_sec := 0.0
var _nav_warned := false
var _wool_tween: Tween = null

func _ready() -> void:
	$AnimatedSprite2D.play("stand")
	$WoolSprite.modulate.a = 1.0
	_follow_delay = randf_range(0.1, 0.8)
	$NavigationAgent2D.target_position = global_position
	$NavigationAgent2D.target_desired_distance = 8.0

func reset_follow_delay() -> void:
	_follow_delay = randf_range(0.1, 0.8)

func clear_follow_delay() -> void:
	_follow_delay = 0.0

func is_at_target() -> bool:
	return $NavigationAgent2D.is_navigation_finished()

func set_follow_target(target_pos: Vector2) -> void:
	$NavigationAgent2D.target_position = target_pos
	_nav_elapsed_sec = 0.0
	_nav_warned = false

func stop() -> void:
	$NavigationAgent2D.target_position = global_position
	set_walking(false)

func _process(delta: float) -> void:
	_sync_layers()
	if _is_eating:
		return
	if not $NavigationAgent2D.is_navigation_finished():
		_nav_elapsed_sec += delta
		if _nav_elapsed_sec >= 10.0 and not _nav_warned:
			_nav_warned = true
			push_error("[Sheep] Navigation stuck! pos=%s  target=%s  dist=%.1f  path_length=%d" % [
				str(global_position), str($NavigationAgent2D.target_position),
				global_position.distance_to($NavigationAgent2D.target_position),
				$NavigationAgent2D.get_current_navigation_path().size()])
	else:
		_nav_elapsed_sec = 0.0
		_nav_warned = false
	if _follow_delay > 0.0:
		_follow_delay -= delta
		set_walking(false)
		return
	if $NavigationAgent2D.is_navigation_finished():
		set_walking(false)
		return
	var next: Vector2 = $NavigationAgent2D.get_next_path_position()
	var dir := next - global_position
	var dist := dir.length()
	if dist > 0.5:
		set_walking(true)
		var step := Constants.sheep_follow_speed * delta
		if step >= dist:
			position += dir
		else:
			position += dir.normalized() * step
	else:
		set_walking(false)

func _sync_layers() -> void:
	var body := $AnimatedSprite2D
	if $WoolSprite.animation != body.animation:
		$WoolSprite.animation = body.animation
	$WoolSprite.frame = body.frame
	$WoolSprite.flip_h = body.flip_h
	if $HeadSprite.animation != body.animation:
		$HeadSprite.animation = body.animation
	$HeadSprite.frame = body.frame
	$HeadSprite.flip_h = body.flip_h

func set_eating(eating: bool) -> void:
	if eating == _is_eating:
		return
	_is_eating = eating
	_is_walking = false
	if eating:
		$NavigationAgent2D.target_position = global_position
		$AnimatedSprite2D.play("eat")
		if is_sheared:
			_tween_wool(0.0, 1.0, Constants.sheep_eat_time_ms / 1000.0)
	else:
		$AnimatedSprite2D.play("stand")

func set_walking(walking: bool) -> void:
	if _is_eating:
		return
	if walking == _is_walking:
		return
	_is_walking = walking
	$AnimatedSprite2D.play("walk" if walking else "stand")

func shear() -> void:
	is_sheared = true
	_is_eating = false
	_is_walking = false
	$AnimatedSprite2D.play("stand")
	_tween_wool(1.0, 0.0, 0.5)

func regrow() -> void:
	is_sheared = false
	_is_eating = false
	_is_walking = false
	$AnimatedSprite2D.play("stand")
	if _wool_tween != null and _wool_tween.is_running():
		_wool_tween.kill()
	$WoolSprite.modulate.a = 1.0

func _tween_wool(from: float, to: float, duration: float) -> void:
	if _wool_tween != null and _wool_tween.is_running():
		_wool_tween.kill()
	$WoolSprite.modulate.a = from
	_wool_tween = create_tween()
	_wool_tween.tween_property($WoolSprite, "modulate:a", to, duration)
