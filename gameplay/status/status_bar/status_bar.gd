@tool
class_name StatusBar
extends Control

@onready var title_control: Control = $Title
@onready var title_label: Label = $Title/Label
@onready var health_bar: Control = $HealthBar
@onready var health_bar_background: ColorRect = $HealthBar/Background
@onready var health_bar_fill: ColorRect = $HealthBar/Background/Fill
@onready var shield_bar: Control = $ShieldBar
@onready var shield_bar_background: ColorRect = $ShieldBar/Background
@onready var shield_bar_fill: ColorRect = $ShieldBar/Background/Fill

@export var connected_status: Status
@export var max_health: float = 100
@export var cur_health: float = 100
@export var max_shield: float = 0
@export var cur_shield: float = 0
@export var shield_enabled: bool = 0


func set_title(_title: String = ""):
	if _title != "":
		title_label.text = _title
	title_control.visible = _title != ""


func set_max_health(_max_health: float):
	max_health = _max_health
	update_health()


func set_cur_health(_cur_health: float):
	cur_health = _cur_health
	update_health()


func update_health():
	health_bar_fill.anchor_right = cur_health/max_health


func set_shield_enabled(_shield_enabled: float):
	shield_enabled = _shield_enabled
	update_shield()


func set_max_shield(_max_shield: float):
	max_shield = _max_shield
	update_shield()


func set_cur_shield(_cur_shield: float):
	cur_shield = _cur_shield
	update_shield()


func update_shield():
	shield_bar.visible = shield_enabled
	var amount = cur_shield/max_shield
	if max_shield == 0:
		amount = 0
	shield_bar_fill.anchor_right = amount


func connect_status(status: Status):
	connected_status = status
	set_max_health(status.max_health)
	set_cur_health(status.cur_health)
	set_max_shield(status.max_shield)
	set_cur_shield(status.cur_shield)
	set_shield_enabled(status.shield_enabled)
	status.health_changed.connect(set_cur_health)
	status.shield_changed.connect(set_cur_shield)
	status.shield_enabled_changed.connect(set_shield_enabled)


func disconnect_status():
	connected_status.health_changed.disconnect(set_cur_health)
	connected_status = null


func _exit_tree() -> void:
	if connected_status:
		disconnect_status()
