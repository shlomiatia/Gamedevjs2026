class_name Sheep
extends Node2D

const REGROW_TIME := 30.0

var is_sheared := false
var targeted := false
var _regrow_timer := 0.0

func _ready() -> void:
	$AnimatedSprite2D.play("unsheared_stand")

func _process(delta: float) -> void:
	if is_sheared:
		_regrow_timer += delta
		if _regrow_timer >= REGROW_TIME:
			_regrow_timer = 0.0
			regrow()

func set_walking(walking: bool) -> void:
	if is_sheared:
		$AnimatedSprite2D.play("sheared_walk" if walking else "sheared_stand")
	else:
		$AnimatedSprite2D.play("unsheared_walk" if walking else "unsheared_stand")

func shear() -> void:
	is_sheared = true
	_regrow_timer = 0.0
	$AnimatedSprite2D.play("sheared_stand")

func regrow() -> void:
	is_sheared = false
	$AnimatedSprite2D.play("unsheared_stand")
