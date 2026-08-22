class_name DungeonMinimap
extends Control

const unvisited_color: Color = Color(0.5, 0.5, 0.5, 0.75)
const visited_color: Color = Color(1, 1, 1, 0.75)

@onready var shapes: Control = $Shapes
@onready var player_marker: Control = $PlayerMarker
@onready var level_label: Label = $LevelLabel

@export var rotate_player_marker: bool = true

var minimap_size: Vector2 = size

var dungeon: Dungeon
var structure_rects: Dictionary[Structure, ColorRect] = {}


func update_player_location(player_rotation: Vector3, player_position: Vector3) -> void:
	shapes.position = minimap_size/2 - Vector2(player_position.x, player_position.z)
	
	if rotate_player_marker:
		player_marker.rotation = -player_rotation.y
		shapes.rotation = 0
	else:
		player_marker.rotation = 0
		shapes.rotation = player_rotation.y
		shapes.pivot_offset = Vector2(player_position.x, player_position.z)


func set_structure_state(structure: Structure, state: Structure.StructureState):
	if state != Structure.StructureState.UNEXPLORED:
		structure_rects[structure].color = visited_color


func set_dungeon(new_dungeon: Dungeon):
	dungeon = new_dungeon
	
	dungeon.loading_start.connect(hide)
	dungeon.loaded.connect(load_dungeon)


func load_dungeon():
	level_label.text = "%d-%d" % [dungeon.world, dungeon.level]
	
	for child in shapes.get_children():
		child.queue_free()
	
	for structure: Structure in dungeon.structures:
		for collision_shape: CollisionShape3D in structure.interior_area.get_children():
			var shape: BoxShape3D = collision_shape.shape
			
			var rect_size := Vector2(shape.size.x, shape.size.z)
			var rect_pos := Vector2(
				collision_shape.global_position.x - rect_size.x/2, 
				collision_shape.global_position.z - rect_size.y/2
			)
			
			var rect = ColorRect.new()
			rect.size = rect_size
			rect.rotation = collision_shape.global_rotation.y
			rect.position = rect_pos
			rect.pivot_offset_ratio = Vector2.ONE/2
			rect.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
			rect.color = unvisited_color
			shapes.add_child(rect)
			structure_rects[structure] = rect
			
			structure.state_changed.connect(func(new_state):
				set_structure_state(structure, new_state))
	
	show()
