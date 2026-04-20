class_name Sheep
extends Node2D

var is_sheared := false
var _is_walking := false
var _is_eating := false
var _follow_delay := 0.0
var _process_delta := 0.0

func _ready() -> void:
	$AnimatedSprite2D.play("unsheared_stand")
	_follow_delay = randf_range(0.1, 0.8)
	$NavigationAgent2D.velocity_computed.connect(_on_velocity_computed)
	$NavigationAgent2D.target_position = global_position

func reset_follow_delay() -> void:
	_follow_delay = randf_range(0.1, 0.8)

func set_follow_target(target_pos: Vector2) -> void:
	$NavigationAgent2D.target_position = target_pos

func stop() -> void:
	$NavigationAgent2D.target_position = global_position
	set_walking(false)

func _process(delta: float) -> void:
	_process_delta = delta
	if _is_eating:
		return
	if _follow_delay > 0.0:
		_follow_delay -= delta
		set_walking(false)
		return
	if $NavigationAgent2D.is_navigation_finished():
		set_walking(false)
		return
	var next: Vector2 = $NavigationAgent2D.get_next_path_position()
	var desired := (next - global_position).normalized() * Constants.sheep_follow_speed
	$NavigationAgent2D.velocity = desired

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if _is_eating:
		return
	if safe_velocity.length() > 5.0:
		set_walking(true)
		position += safe_velocity * _process_delta
	else:
		set_walking(false)

func set_eating(eating: bool) -> void:
	if eating == _is_eating:
		return
	_is_eating = eating
	_is_walking = false
	if eating:
		$NavigationAgent2D.target_position = global_position
		$AnimatedSprite2D.play("sheared_eat" if is_sheared else "unsheared_eat")
	else:
		$AnimatedSprite2D.play("sheared_stand" if is_sheared else "unsheared_stand")

func set_walking(walking: bool) -> void:
	if _is_eating:
		return
	if walking == _is_walking:
		return
	_is_walking = walking
	if is_sheared:
		$AnimatedSprite2D.play("sheared_walk" if walking else "sheared_stand")
	else:
		$AnimatedSprite2D.play("unsheared_walk" if walking else "unsheared_stand")

func shear() -> void:
	is_sheared = true
	_is_eating = false
	_is_walking = false
	$AnimatedSprite2D.play("sheared_stand")

func regrow() -> void:
	is_sheared = false
	_is_eating = false
	_is_walking = false
	$AnimatedSprite2D.play("unsheared_stand")
