extends Control


func _ready() -> void:
	if OS.has_feature("mobile"):
		get_viewport().get_window().content_scale_factor = 2
		visible = true
	else:
		queue_free()
