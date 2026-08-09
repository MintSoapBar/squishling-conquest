class_name FollowPlayerGoal
extends Goal


func _init(mob_: Mob):
	super(mob_)

	priority = 10
	start_cooldown = 1000
	active_cooldown = 1000


func can_start() -> bool:
	if not super():
		return false
	
	return true


func start():
	pass


func stop():
	pass
