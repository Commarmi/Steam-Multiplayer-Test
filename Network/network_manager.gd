class_name NetworkManager
extends Node

@export var player_scene: PackedScene

@onready var game_world: Node2D = $Game
@onready var ui_menu: Control = $Control
@onready var lobby_list: VBoxContainer = $Control/ScrollContainer/ListaPartidas

var peer := SteamMultiplayerPeer.new()
var hosted_lobby_id: int = 0

func _ready() -> void:
	# 1. Inicializamos usando el ID 480 (Juego de pruebas de Steam: Spacewar)
	var init_response: Dictionary = Steam.steamInitEx(false, 480)
	print("Estado de inicialización: ", init_response)
	
	if init_response.has("status") and init_response["status"] != 0:
		print("ERROR: Steam no está abierto o no pudo conectar.")
		return
	
	# 2. Conectamos las señales principales de Steam
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	# 3. Conectamos la señal de red de Godot (para saber cuándo entra un jugador al mundo)
	multiplayer.peer_connected.connect(_on_peer_connected)

# ¡ESTO ES CRUCIAL! 
# Obliga a Godot a procesar los mensajes de Steam constantemente.
func _process(_delta: float) -> void:
	Steam.run_callbacks()

# Conectado a la señal 'pressed' del BtnHost
func host_game() -> void:
	print("Pidiendo a Steam que cree un lobby...")
	# LOBBY_TYPE_PUBLIC = 2. Max 4 jugadores.
	Steam.createLobby(2, 4) 

# Steam nos responde aquí automáticamente:
func _on_lobby_created(connect_flag: int, lobby_id: int) -> void:
	if connect_flag == 1: # 1 es éxito
		hosted_lobby_id = lobby_id
		print("Lobby creado en Steam. ID: ", lobby_id)
		
		# Le ponemos un nombre al lobby para que otros lo vean
		var host_name: String = Steam.getPersonaName()
		Steam.setLobbyData(lobby_id, "name", "Sala de " + host_name)
		
		# AHORA SÍ: Encendemos el servidor de red de Godot
# AHORA SÍ: Encendemos el servidor de red de Godot
		var error: Error = peer.create_host(0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			ui_menu.hide()
			
			# ESTA LÍNEA ES LA QUE CAMBIAMOS
			var my_id = multiplayer.get_unique_id() # ¡Para el host, esto siempre devolverá 1!
			spawn_player(my_id)
		else:
			print("Error al iniciar el host de Godot.")
# Conectado a la señal 'pressed' del BtnSearch
func search_lobbies() -> void:
	print("Buscando partidas en Steam...")
	# Limpiamos la lista de la UI por si había botones viejos
	for child in lobby_list.get_children():
		child.queue_free()
		
	# Buscamos partidas en todo el mundo
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

# Steam nos devuelve la lista aquí:
func _on_lobby_match_list(lobbies: Array) -> void:
	print("Partidas encontradas: ", lobbies.size())
	
	for lobby_id in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby_id, "name")
		if lobby_name == "":
			lobby_name = "Partida sin nombre"
			
		# Creamos un botón para cada partida
		var btn := Button.new()
		btn.text = lobby_name
		btn.pressed.connect(join_lobby.bind(lobby_id))
		lobby_list.add_child(btn)

func join_lobby(lobby_id: int) -> void:
	print("Intentando entrar al lobby de Steam...")
	Steam.joinLobby(lobby_id)

# Steam confirma que hemos entrado a la sala:
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1: 
		print("Dentro del lobby. Conectando motores de red...")
		
		var host_steam_id: int = Steam.getLobbyOwner(lobby_id)
		
		# EL FIX: Si yo soy el creador del lobby, me salgo de la función.
		# No necesito ser cliente de mi propio servidor.
		if host_steam_id == Steam.getSteamID():
			print("Soy el Host, ignoro la creación del cliente.")
			return
		
		# Si llegamos aquí, significa que somos un Cliente real uniéndose a otro
		var error: Error = peer.create_client(host_steam_id, 0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			ui_menu.hide()
			print("¡Conectado! Esperando a aparecer en el mundo.")
		else:
			print("Error al iniciar el cliente: ", error)
# Godot lanza esto cuando un cliente logra conectarse por red P2P
func _on_peer_connected(id: int) -> void:
	print("Jugador de Steam conectado a mi red con ID: ", id)
	
	# Solo el Host tiene derecho a meter jugadores en el mundo
	if multiplayer.is_server():
		spawn_player(id)

func spawn_player(steam_id: int) -> void:
	var player_instance = player_scene.instantiate()
	player_instance.name = str(steam_id) # El truco mágico de la autoridad
	game_world.add_child(player_instance)
