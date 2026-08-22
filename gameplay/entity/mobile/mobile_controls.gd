extends Control


func _ready() -> void:
	if OS.has_feature("mobile"):
		visible = true
	else:
		queue_free()
