extends Sprite

@onready var body: SquishlingSpriteBody = $Model/Body
@onready var shield: Node3D = $Model/Body/Shield

var unstretched_default_hand_transform: Transform3D
var status_billboard_pos: Vector3

func _ready():
	super()
	
	body.entity = entity
	unstretched_default_hand_transform = default_hand_transform
	status_billboard_pos = status_bar_billboard.position
	
	body.stretched.connect(on_body_stretched)


func on_body_stretched():
	default_hand_transform.origin = body.position + \
		body.get_deformed_vertex_pos(unstretched_default_hand_transform.origin)
	status_bar_billboard.position = body.get_deformed_vertex_pos(status_billboard_pos)


func set_shield_visible(shield_visible: bool):
	shield.visible = shield_visible


@rpc("authority", "call_local")
func set_body_color(color := Color(1, 0, 1)):
	body.set_color(color)
