class_name Rig
extends Mob

var first_fire_delay_min: float = 1
var first_fire_delay_max: float = 2
var charge_time_min: float = 0.5
var charge_time_max: float = 1
var fire_interval_min: float = 1
var fire_interval_max: float = 3

var next_fire: float = GameTime.get_unpaused_elapsed_time() + (
	randf_range(first_fire_delay_min, first_fire_delay_max))


func _ready() -> void:
	super()
	
	inventory.add_stack(Stack.new("magic_staff", 1))
	equip_tool(0)


func _physics_process(delta: float) -> void:
	super(delta)
	
	if not can_move():
		return
	
	update_target()
	if target:
		movement_target_position = target.global_position
		step_attack()
