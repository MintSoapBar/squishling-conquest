class_name StatusBarBillboard
extends Sprite3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var status_bar: StatusBar = $SubViewport/StatusBar


func _ready() -> void:
	status_bar.set_title("")
	texture = sub_viewport.get_texture()


func connect_status(status: Status):
	status_bar.connect_status(status)
