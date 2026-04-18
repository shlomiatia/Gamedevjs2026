class_name Sheep
extends Node2D

var is_sheared := false

func _ready() -> void:
	$AnimatedSprite2D.play("unsheared_stand")

func follow_toward(target_pos: Vector2, delta: float) -> void:
	var dir := target_pos - position
	var dist := dir.length()
	if dist <= Constants.sheep_follow_stop_distance:
		set_walking(false)
		return
	set_walking(true)
	position += dir.normalized() * Constants.sheep_follow_speed * delta

func set_walking(walking: bool) -> void:
	if is_sheared:
		$AnimatedSprite2D.play("sheared_walk" if walking else "sheared_stand")
	else:
		$AnimatedSprite2D.play("unsheared_walk" if walking else "unsheared_stand")

func shear() -> void:
	is_sheared = true
	$AnimatedSprite2D.play("sheared_stand")

func regrow() -> void:
	is_sheared = false
	$AnimatedSprite2D.play("unsheared_stand")
