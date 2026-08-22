class_name Client
extends Node

signal room_joining()
signal room_joined()
signal room_left()
signal room_closed()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var udp: PacketPeerUDP
var peer: ENetMultiplayerPeer

@onready var network: Network = $".."
var server: Server

var searching := false
var connecting := false
var in_room := false

func debug_prints(...vals: Array):
	return network.debug_prints.callv(vals)


func _ready():
	await network.ready
	server = network.server
	
	multiplayer.peer_connected.connect(func(peer_id: int):
		if not in_room:
			return
		
		debug_prints(peer_id, "connected")
		peer_connected.emit(peer_id)
	)
	
	multiplayer.peer_disconnected.connect(func(peer_id: int):
		if not in_room:
			return
		
		debug_prints(peer_id, "disconnected")
		peer_disconnected.emit(peer_id)
	)
	
	multiplayer.connected_to_server.connect(func():
		in_room = true
		
		debug_prints("Room joined")
		room_joined.emit()
	)
	
	multiplayer.server_disconnected.connect(func():
		if not in_room:
			return
		
		debug_prints("Room closed")
		room_closed.emit()
	)
	
	multiplayer.connection_failed.connect(func():
		debug_prints("Connection failed")
	)


func _process(_delta):
	if not searching:
		return
	
	if udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		var msg = packet.get_string_from_utf8()
		
		if msg.begins_with("GAME|"):
			var parts = msg.split("|")
			var ip = parts[1]
			var port = int(parts[2])

			debug_prints("Found host:", ip, port)
			
			stop_searching()
			join_room(ip, port)


func join_room(ip: String, port: int = server.game_port):
	if server.hosting_room:
		await server.close_room()
	if peer:
		await leave_room()
	
	room_joining.emit()
	
	network.transitioning = true
	connecting = true
	
	peer = ENetMultiplayerPeer.new()
	var msg = peer.create_client(ip, port)
	
	if msg == 0:
		multiplayer.multiplayer_peer = peer
	else:
		debug_prints("Unable to connect client. Check the server address. Error:", 
			msg, error_string(msg))
	
	
	network.transitioning = false
	connecting = false


func leave_room():
	if not peer:
		return
	
	network.transitioning = true
	
	peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	
	network.transitioning = false
	connecting = false
	in_room = false
	
	debug_prints("Left room")
	room_left.emit()


func stop_searching():
	network.transitioning = true
	
	if udp:
		udp.close()
		udp = null
	
	network.transitioning = false
	searching = false
	
	debug_prints("Stopped searching for rooms")


func start_searching():
	if server.hosting_room:
		await server.close_room()
	if searching:
		await stop_searching()
	
	network.transitioning = true
	
	udp = PacketPeerUDP.new()
	var err = udp.bind(server.BROADCAST_PORT)
	
	network.transitioning = false
	searching = true
	
	if err == 0:
		debug_prints("Searching for rooms")
	else:
		debug_prints("UDP bind error. Check your internet connection. Error:", error_string(err))
		stop_searching()
