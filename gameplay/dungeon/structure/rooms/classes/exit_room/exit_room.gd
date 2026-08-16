class_name ExitRoom
extends Room

signal player_entered_gate(player: Player)

var gate: Gate

func initialize() -> void:
	super()
	
	gate = $Gate
	gate.player_entered.connect(on_gate_player_entered)


func on_gate_player_entered(player: Player):
	player_entered_gate.emit(player)


func generate_interior_area():
	if interior_area:
		return
	
	interior_area = $InteriorArea
	interior_area.body_entered.connect(on_interior_area_body_entered)
