@abstract
class_name Goal
extends Resource

var control_ids: Array[String] = []
var priority := 10
var start_cooldown := 1000
var active_cooldown := 1000

var active := false
var last_start_time := 0
var last_stop_time := 0

var mob: Mob


func _init(mob_: Mob):
	mob = mob_


func can_start() -> bool:
	var cur_time = Time.get_ticks_msec()
	if cur_time - last_start_time < start_cooldown:
		return false
	if cur_time - last_stop_time < active_cooldown:
		return false
	
	if !mob.is_alive():
		return false
	
	return true


func start():
	active = true
	last_start_time = Time.get_ticks_msec()
	
	for control_id in control_ids:
		mob.controls[control_id] = self


func stop():
	active = false
	last_stop_time = Time.get_ticks_msec()
	
	for control_id in control_ids:
		mob.controls.erase(control_id)
