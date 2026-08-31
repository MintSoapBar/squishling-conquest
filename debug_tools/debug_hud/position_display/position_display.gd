extends Label


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if not cam:
		text = "Pos: null"
	else:
		var pos = cam.global_position
		text = "Pos: %.2f, %.2f, %.2f" % [pos.x, pos.y, pos.z] 
