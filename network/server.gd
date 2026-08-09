class_name Server
extends Node


signal room_opened()
signal room_closing()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)


const game_port := 20260
const BROADCAST_PORT := 20261
const BROADCAST_INTERVAL := 1.0

const MAX_PLAYERS := 10

var peer: ENetMultiplayerPeer
var udp: PacketPeerUDP
var broadcast_timer := 0.0

var hosting_room := false

@onready var network: Network = $".."
var client: Client
var debug_printer


func debug_prints(...vals: Array):
	return network.debug_prints.callv(vals)


func _ready():
	await network.ready
	client = network.client
	debug_printer = network.debug_printer
	
	multiplayer.peer_connected.connect(func(peer_id: int):
		if not hosting_room:
			return
		
		debug_prints(peer_id, "connected")
		peer_connected.emit(peer_id)
	)
	
	multiplayer.peer_disconnected.connect(func(peer_id: int):
		if not hosting_room:
			return
		
		debug_prints(peer_id, "disconnected")
		peer_disconnected.emit(peer_id)
	)


func _process(delta):
	broadcast_timer += delta
	if broadcast_timer < BROADCAST_INTERVAL:
		return
	
	if not hosting_room:
		return

	broadcast_timer = 0.0

	var msg = "GAME|" + get_lan_ip() + "|" + str(game_port)
	var packet = msg.to_utf8_buffer()

	var ip = "255.255.255.255"
	udp.set_dest_address(ip, BROADCAST_PORT)
	udp.put_packet(packet)


func close_room():
	assert(hosting_room, "This player is not hosting a room")
	
	network.transitioning = true
	
	room_closing.emit()
	
	if peer:
		peer.close()
		peer = null
	
	if udp:
		udp.close()
		udp = null
	
	multiplayer.multiplayer_peer = null
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	network.transitioning = false
	hosting_room = false
	
	debug_prints("Room closed")


func host_room(port: int = game_port):
	if client.searching:
		await client.stop_searching()
	if client.in_room:
		await client.leave_room()
	if hosting_room:
		await close_room()
	
	network.transitioning = true
	
	peer = ENetMultiplayerPeer.new()
	udp = PacketPeerUDP.new()

	udp.set_broadcast_enabled(true)
	
	# start ENet server
	var err = peer.create_server(port, MAX_PLAYERS)
	if err != OK: 
		debug_prints("Unable to host room. Error:", err, error_string(err))
		close_room()
		return
	
	multiplayer.multiplayer_peer = peer
	
	network.transitioning = false
	hosting_room = true
	
	room_opened.emit()

	debug_prints("Host started on port", game_port)


func get_lan_ip() -> String:
	for ip in IP.get_local_addresses():
		if is_lan_ipv4(ip):
			return ip
	return "127.0.0.1"


func is_lan_ipv4(ip: String) -> bool:
	if ip == "127.0.0.1":
		return false
	if ":" in ip:
		return false # filters IPv6

	return ip.begins_with("192.168.") \
		or ip.begins_with("10.") \
		or ip.begins_with("172.")
