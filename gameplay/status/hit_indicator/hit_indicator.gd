@tool
class_name HitIndicator
extends Label3D

const HIT_INDICATOR = preload("uid://3a4got1ccrc6")

@export_category("Editor Testing")
@export var editor_test: bool = false:
	set(val):
		if val == true:
			var indicator: HitIndicator = duplicate()
			owner.add_child(indicator)
			indicator.global_position = self.global_position + Vector3.UP
			indicator.editor_animate = true
			
			await get_tree().process_frame
			editor_test = false
var editor_animate: bool = false:
	set(val):
		editor_animate = val
		if editor_animate == true:
			start_time = Time.get_unix_time_from_system()

@export_category("General Settings")
@export var color: Color = Color(1, 0, 0)

@export_category("Visibility")
@export var max_dist = 100
@export var min_scale = 0.02
@export var opaque_lifetime: float = 0.5
@export var max_lifetime: float = 1
var start_time: float = Time.get_unix_time_from_system()

@export_category("Movement")
@export var vertical_drift: float = 60
@export var horizontal_drift_min: float = -60
@export var horizontal_drift_max: float = 60
var horizontal_offset: float = horizontal_drift_min + (atan(PI*(randf()-0.5))/2+0.5) * (
								horizontal_drift_max - horizontal_drift_min)

@export_category("Flash")
@export var flash_enabled: bool = false
@export var flash_color: Color = Color(1, 1, 0)
@export var flash_opacity: float = 0.5
@export var flash_ratio: float = 0.5
@export var flash_period: float = 0.15
@export var flash_lifetime: float = INF


static func create_hit_indicator() -> HitIndicator:
	return HIT_INDICATOR.instantiate()


func _ready() -> void:
	_process(0)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and not editor_animate:
		return
	
	var camera: Camera3D
	#if Engine.is_editor_hint():
		#var viewport := EditorInterface.get_editor_viewport_3d()
		#camera = viewport.get_camera_3d()
	#else:
	camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var dist = (camera.global_position - global_position).length()
	if dist > max_dist:
		visible = false
		return
	visible = true
	
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_width: float = min(screen_size.x, screen_size.y)
	
	# dividing by pixel_size cancels it out
	var screen_scale: float = font_size/screen_width / pixel_size / 20
	var distance_scale = lerp(1.0, min_scale, dist/max_dist)
	scale = Vector3.ONE * screen_scale * distance_scale
	
	var lifetime = Time.get_unix_time_from_system() - start_time
	var lifetime_progress = lifetime / max_lifetime
	if lifetime_progress >= 1:
		queue_free()
		return
	
	var cur_color = color
	if flash_enabled and lifetime <= flash_lifetime:
		var flash_progress = fmod(lifetime/flash_period, 1)
		if (flash_ratio > 0 and flash_progress < flash_ratio 
			or flash_ratio < 0 and flash_progress > -flash_ratio):
				
			var flash_lifetime_opacity = 1 - lifetime/flash_lifetime
			var absolute_flash_color = color.lerp(flash_color, flash_opacity)
			cur_color = color.lerp(absolute_flash_color, flash_lifetime_opacity)
	
	var opacity = 1
	if lifetime > opaque_lifetime:
		var translucent_lifetime: float = max_lifetime - opaque_lifetime
		opacity = 1 - ((lifetime - opaque_lifetime) / translucent_lifetime)
	
	offset.y = vertical_drift * distance_scale * (lifetime_progress ** 2.5)
	offset.x = horizontal_offset * distance_scale * (lifetime_progress ** 0.5)
	
	modulate = Color(cur_color, opacity)
	outline_modulate = Color(color * 0.25, opacity * 0.9)
