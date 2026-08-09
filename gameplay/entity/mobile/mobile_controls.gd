extends Control


func _ready() -> void:
	if OS.has_feature("mobile"):
		get_tree().root.content_scale_factor = 2.0
	else:
		queue_free()
