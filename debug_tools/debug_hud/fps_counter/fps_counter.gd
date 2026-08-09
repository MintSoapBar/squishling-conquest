extends Label

const text_format = "FPS: %.2f"

@export var per_frame: bool = false

var count_time := 0.0
var frames := 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frames += 1
	count_time += delta
	
	if count_time >= 1:
		var extra_time = count_time - 1
		var extra_frame_percent = extra_time/delta
		frames -= extra_frame_percent
		
		text = text_format % frames
		
		count_time = 0
		frames = 0
	
	if per_frame:
		text = text_format % (1/delta)
