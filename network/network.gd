class_name Network
extends Node

signal ip_found(String)

var server_authority: bool = false

var transitioning: bool = false

@export var debug_printer: Node = null

@onready var server: Server = $Server
@onready var client: Client = $Client

@onready var http_request: HTTPRequest = $IPHTTPRequest


func debug_prints(...vals: Array) -> void:
	if not debug_printer:
		return
	
	(debug_printer.prints_ as Callable).callv(vals)


func is_multiplayer_connected() -> bool:
	return multiplayer.has_multiplayer_peer() and (
		multiplayer.multiplayer_peer.get_connection_status() == (
			MultiplayerPeer.CONNECTION_CONNECTED))


func get_public_ip_via_http_req() -> void:
	var error = http_request.request("https://icanhazip.com")
	if error != OK:
		push_warning("An error occurred while making the HTTP request.")


func _on_iphttp_request_request_completed(
	_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var public_ip: String = body.get_string_from_utf8().strip_edges()
		ip_found.emit(public_ip)
	else:
		ip_found.emit("HTTP Error: " + str(response_code))

func get_public_ip_via_upnp() -> String:
	var upnp = UPNP.new()
	
	# Discover the gateway device on the local network
	# (2000ms timeout, 2 TTL hops, filtering for InternetGatewayDevice)
	var discover_result = upnp.discover(2000, 2, "InternetGatewayDevice")
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		var external_ip := upnp.query_external_address()
		if not external_ip.is_empty():
			return external_ip
		else:
			return ""
	else:
		# error code is discover_result
		return ""
