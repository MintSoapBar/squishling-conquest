extends Node3D

const HOME = preload("uid://d2ru382ltbalf")

@onready var entities_folder: EntitiesFolder = $EntitiesFolder
@onready var core_3d_interface: Node = $Core3DInterface
@onready var dungeon: Dungeon = $Dungeon
@onready var minimap: DungeonMinimap = $Minimap

var home: Home


func _ready() -> void:
	Entity.initialize_registry()
	Entity.set_folder(entities_folder)
	Tool.initialize_registry()
	Skill.initialize_registry()
	core_3d_interface.initialize()
	
	home = HOME.instantiate()
	add_child(home)
	
	Player.create_player()
	
	home.player_entered_dungeon_gate.connect(on_dungeon_gate_player_enter, CONNECT_ONE_SHOT)
	Entity.entities_folder.local_player_changed.connect(try_regenerate)
	dungeon.player_entered_exit_gate.connect(func(_player: Player):
		regenerate())


func _process(_delta: float) -> void:
	if Player.local_player:
		var camera := get_viewport().get_camera_3d()
		minimap.update_player_location(camera.global_rotation, Player.local_player.position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_BACKSPACE and key_event.is_pressed():
			if is_instance_valid(home):
				home.queue_free()
			regenerate()
			get_viewport().set_input_as_handled()


func regenerate():
	await dungeon.generate()
	minimap.load_dungeon_shapes(dungeon)


func try_regenerate(plr):
	if plr:
		regenerate()


func on_dungeon_gate_player_enter(_player: Player):
	regenerate()
	home.queue_free()
