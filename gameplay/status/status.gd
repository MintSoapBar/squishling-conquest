class_name Status
extends Node

const STATUS = preload("uid://bp1n8ugn1h3hf")

signal damaged(amount: float, attributes: Dictionary[String, bool])
signal healed(amount: float, attributes: Dictionary[String, bool])
signal status_effect_added(status_effect: StatusEffect)
signal health_changed(new_health: float)
signal shield_changed(new_shield: float)
signal shield_enabled_changed(new_enabled: bool)

static var attribute_colors: Dictionary[String, Color] = {
	
}

var resistances: Dictionary[int, float] = {}

var cur_health: float
var max_health: float

var cur_shield: float = 0
var max_shield: float = 0
var shield_repair_delay: float = 5.0
var shield_regen: float = 20.0
var next_shield_repair_time: float = 0

var status_effects: Dictionary[String, StatusEffect] = {}

var shield_enabled: bool = true

var dead: bool = false

var damage_callback: Callable = Callable()
var heal_callback: Callable = Callable()


static func _static_init() -> void:
	for magic: String in MagicVisuals.magic_colors:
		var colors: Array = MagicVisuals.magic_colors[magic]
		attribute_colors[magic] = colors[0]


static func create_status() -> Status:
	return STATUS.instantiate()


func _process(_delta: float) -> void:
	if (Entity.network and Entity.network.is_multiplayer_connected() 
		and not is_multiplayer_authority()):
		
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	var cur_time = GameTime.get_ticks_sec()
	if cur_shield >= max_shield:
		next_shield_repair_time = cur_time
	elif cur_time >= next_shield_repair_time:
		next_shield_repair_time += 1
		repair_shield.rpc(shield_regen)


static func get_attributes_color(attributes: Dictionary[String, bool]):
	var colors: Array[Color] = []
	for attribute in attributes:
		var attribute_color = attribute_colors.get(attribute)
		if attribute_color:
			colors.append(attribute_color)
	
	var color: Color = Color.BLACK
	
	for attribute_color in colors:
		color += attribute_color / colors.size()
	
	color.a = 1
	
	return color


static func get_health_change_string(
	health_change: float, _attributes: Dictionary[String, bool] = {}) -> String:
	
	if abs(health_change) >= 100:
		return "%+d" % health_change
	else:
		return "%+.1f" % health_change


static func create_status_effect_indicator(
	status_effect: String) -> HitIndicator:
	
	var indicator := HitIndicator.create_hit_indicator()
	indicator.text = status_effect
	
	return indicator


static func create_hit_indicator(
	health_change: float, attributes: Dictionary[String, bool] = {}) -> HitIndicator:
	
	var indicator := HitIndicator.create_hit_indicator()
	indicator.text = Status.get_health_change_string(health_change, attributes)
	
	if attributes.get("dot"):
		indicator.color = get_attributes_color(attributes)
	else:
		indicator.color = Color.RED if health_change <= 0 else Color.GREEN
	
	return indicator


@rpc("any_peer", "call_local")
func enable_shield() -> void:
	shield_enabled = true
	shield_enabled_changed.emit(true)


@rpc("any_peer", "call_local")
func disable_shield() -> void:
	shield_enabled = false
	shield_enabled_changed.emit(false)


@rpc("any_peer", "call_local")
func damage(amount: float, attributes: Dictionary[String, bool] = {}):
	if dead:
		return
	
	assert(amount >= 0, "Damage amount cannot be a negative value")
	
	next_shield_repair_time = GameTime.get_ticks_sec() + shield_repair_delay
	
	var shield_damage: float = min(cur_shield, amount) if shield_enabled else 0
	cur_shield -= shield_damage
	var overflow_damage = amount - shield_damage
	cur_health = clamp(cur_health - overflow_damage, 0, max_health)
	
	damaged.emit(amount, attributes)
	health_changed.emit(cur_health)
	
	if shield_damage > 0:
		shield_changed.emit(cur_shield)
	
	if not attributes.get("dot"):
		for attribute in attributes:
			var effects: Array = StatusEffectBalancing.damage_attribute_effects.get(attribute, [])
			for effect_name: String in effects:
				var effect_stats := StatusEffectBalancing.status_effect_stats[effect_name]
				add_effect(effect_name, effect_stats.health_change * abs(amount), effect_stats.duration)


@rpc("any_peer", "call_local")
func heal(amount: float, attributes: Dictionary[String, bool] = {}):
	if dead:
		return
	
	assert(amount >= 0, "Heal amount cannot be a negative value")
	
	cur_health = clamp(cur_health + amount, 0, max_health)
	healed.emit(amount, attributes)
	health_changed.emit(cur_health)


@rpc("any_peer", "call_local")
func repair_shield(amount: float):
	if dead:
		return
	
	cur_shield = clamp(cur_shield + amount, 0, max_shield)
	shield_changed.emit(cur_shield)


@rpc("any_peer", "call_local")
func remove_status_effect(status_effect_name: String):
	var effect: StatusEffect = status_effects.get(status_effect_name)
	if effect:
		effect.queue_free()
		status_effects.erase(status_effect_name)


@rpc("any_peer", "call_local")
func add_effect(status_effect_name: String, health_change: float, duration: float):
	var status_effect: StatusEffect = status_effects.get(status_effect_name)
	if not status_effect:
		status_effect = StatusEffect.create_status_effect(self, status_effect_name)
		status_effects[status_effect_name] = status_effect
		status_effect_added.emit(status_effect)
		
		if is_multiplayer_authority():
			status_effect.finished.connect(remove_status_effect.rpc.bind(status_effect_name))
		
	status_effect.add_stack(health_change, duration)
