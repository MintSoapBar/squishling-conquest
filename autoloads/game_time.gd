extends Node


var game_time: float = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	game_time += delta


func get_ticks_sec() -> float:
	return game_time


func get_ticks_msec() -> float:
	return game_time * 1000
