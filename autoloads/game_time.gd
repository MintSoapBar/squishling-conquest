extends Node


var elapsedtime: float = 0
var unpaused_elapsed_time: float = 0
var unpaused_scaled_elapsed_time: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	elapsedtime += delta
	if not get_tree().paused:
		unpaused_elapsed_time += delta
		unpaused_scaled_elapsed_time += delta * Engine.time_scale


func get_elapsed_time() -> float:
	return elapsedtime * 1000


func get_unpaused_elapsed_time() -> float:
	return unpaused_elapsed_time


func get_unpaused_scaled_elapsed_time() -> float:
	return unpaused_scaled_elapsed_time
