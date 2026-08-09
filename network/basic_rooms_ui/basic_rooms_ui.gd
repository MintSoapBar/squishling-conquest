extends Control


@export var network: Network
var server: Server
var client: Client

@onready var port_box: TextEdit = $PortSetting/PortBox
@onready var room_address_box: TextEdit = $Hosting/RoomAddressBox
@onready var server_address_box: TextEdit = $Joining/ServerAddressBox


func _ready() -> void:
	assert(network, "Network node must be set for basic rooms ui")
	
	server = network.server
	client = network.client
	
	network.ip_found.connect(on_ip_found)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event = event as InputEventMouseButton
		
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			if port_box.has_focus():
				port_box.release_focus()
			if server_address_box.has_focus():
				server_address_box.release_focus()


func on_ip_found(ip: String):
	room_address_box.text = ip


func _on_host_button_pressed() -> void:
	clean_port_text()
	
	if network.transitioning:
		return
	
	room_address_box.text = "Hosting..."
	await get_tree().process_frame
	await get_tree().process_frame
	network.server.host_room(get_port_id())
	
	network.get_public_ip_via_http_req()


func _on_join_button_pressed() -> void:
	clean_server_address_text()
	clean_port_text()
	
	if network.transitioning:
		return
	
	if not server_address_box.text.is_empty():
		client.join_room(server_address_box.text, get_port_id())
	else:
		client.start_searching()


func get_port_id() -> int:
	var port_string = port_box.text
	if port_string.is_empty():
		port_string = port_box.placeholder_text
	return int(port_string)


func _on_leave_button_pressed() -> void:
	if network.transitioning:
		return
	
	if network.client.searching:
		network.client.stop_searching()
	elif network.client.connecting or network.client.in_room:
		network.client.leave_room()
	elif network.server.hosting_room:
		network.server.close_room()
	else:
		network.debug_prints("You are not in, searching for, or hosting a room")


func _on_server_address_text_changed() -> void:
	if server_address_box.text.contains("\n"):
		server_address_box.release_focus()


func clean_server_address_text() -> void:
	server_address_box.text = server_address_box.text.strip_edges().remove_chars(" \t\n\r")


func _on_port_text_changed() -> void:
	if port_box.text_box.contains("\n"):
		port_box.release_focus()


func clean_port_text() -> void:
	var new_text = str(port_box.text.to_int())
	if new_text == "0":
		new_text = ""
	port_box.text = new_text
