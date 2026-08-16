extends Sprite

@onready var status_bar_billboard: StatusBarBillboard = $StatusBarBillboard
@onready var body: SquishlingSpriteBody = $Model/Body
@onready var hand: Marker3D = $Hand
@onready var shield: Node3D = $Model/Body/Shield

var hand_pos: Vector3
var status_billboard_pos: Vector3

func _ready():
	model = $Model
	
	body.entity = entity
	hand_pos = hand.position
	status_billboard_pos = status_bar_billboard.position
	
	body.stretched.connect(on_body_stretched)


func on_body_stretched():
	hand.position = body.position + body.get_deformed_vertex_pos(hand_pos)
	status_bar_billboard.position = body.get_deformed_vertex_pos(status_billboard_pos)


func set_shield_visible(shield_visible: bool):
	shield.visible = shield_visible


@rpc("authority", "call_local")
func set_body_color(color := Color(1, 0, 1)):
	body.set_color(color)
