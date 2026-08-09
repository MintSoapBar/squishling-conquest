extends Node

@onready var orbital_camera: OrbitalCamera = $OrbitalCamera
@onready var crosshair_cursor: CrosshairCursor = $CrosshairCursor


func initialize() -> void:
	crosshair_cursor.set_orbital_camera(orbital_camera)
	Player.set_orbital_camera(orbital_camera)
