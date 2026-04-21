class_name Miner
extends Node2D


enum State { GO_TO_PILE, MINE }

var _state := State.GO_TO_PILE
var _clay_pit: Node2D = null
var _pile: ResourcePile = null
var _output_scene: PackedScene = null
var _mine_elapsed := 0.0

func setup(clay_pit: Node2D, pile: ResourcePile, output_scene: PackedScene, map: Map, coordination_manager: Node, worker_name: String = "Miner") -> void:
	_clay_pit = clay_pit
	_pile = pile
	_output_scene = output_scene
	$Worker.setup(clay_pit, map, coordination_manager)
	$Worker.display_name = worker_name

func _ready() -> void:
	$Worker.navigate_to(_pile.global_position)

func resume_work() -> void:
	_state = State.GO_TO_PILE
	$Worker.navigate_to(_pile.global_position)

func _process(delta: float) -> void:
	var pile_full: bool = $Worker.is_output_full(_pile)
	$Worker.set_working(_state == State.MINE and not pile_full)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.GO_TO_PILE:
			if $Worker.tick_movement(delta):
				_state = State.MINE
				_mine_elapsed = 0.0
		State.MINE:
			if pile_full:
				return
			_mine_elapsed += delta * 1000.0
			if _mine_elapsed >= Constants.mine_duration_ms:
				_mine_elapsed = 0.0
				_pile.add_resource(_output_scene)
