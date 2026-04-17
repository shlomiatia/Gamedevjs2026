class_name Sheep
extends Node2D

const FOLLOW_SPEED := 80.0
const FOLLOW_STOP_DISTANCE := 16.0

var is_sheared := false

func _ready() -> void:
	$AnimatedSprite2D.play("unsheared_stand")

func follow_toward(target_pos: Vector2, delta: float) -> void:
	var dir := target_pos - position
	var dist := dir.length()
	if dist <= FOLLOW_STOP_DISTANCE:
		set_walking(false)
		return
	set_walking(true)
	position += dir.normalized() * FOLLOW_SPEED * delta

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
