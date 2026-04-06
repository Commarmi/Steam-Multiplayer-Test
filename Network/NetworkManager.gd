extends Node
class_name NetworkManagerClass

# Señales para comunicar a las interfaces visuales
signal player_list_updated
signal search_results_updated(lobbies: Array)
signal lobby_joined_success 

const APP_ID = 480
const GAME_GUID_FILTER = "TestMultiGameV1"

# IMPORTANTE: Ahora empieza en null para evitar el ERR_ALREADY_IN_USE
var peer: SteamMultiplayerPeer = null 
var current_lobby_id: int = 0
var connected_players: Dictionary = {}

func _ready() -> void:
	MenuPausa=MenuPausa.instantiate()
	add_child(MenuPausa)
	var init_response: Dictionary = Steam.steamInitEx(false, APP_ID)
	print("Steam Init: ", init_response)
	
	# Señales de Steam
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	# Señales de Godot Multiplayer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

# ==========================================
# FUNCIÓN CENTRAL DE LIMPIEZA
# ==========================================
func cleanup_network() -> void:
	print("Limpiando estado de la red...")
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	
	peer = null
	current_lobby_id = 0
	connected_players.clear()
	player_list_updated.emit()

# ==========================================
# FUNCIONES QUE LLAMA EL MENU PRINCIPAL
# ==========================================
func start_hosting() -> void:
	cleanup_network() # Limpiamos antes de crear por si acaso
	print("Creando lobby...")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func start_searching() -> void:
	print("Buscando...")
	Steam.addRequestLobbyListStringFilter("game_guid", GAME_GUID_FILTER, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func join_lobby_by_id(lobby_id: int) -> void:
	cleanup_network() # Limpiamos antes de unirnos
	print("Uniéndose al lobby: ", lobby_id)
	Steam.joinLobby(lobby_id)

# ==========================================
# RESPUESTAS DE STEAM Y CONEXIÓN
# ==========================================
func _on_lobby_created(response: int, lobby_id: int) -> void:
	if response == 1:
		current_lobby_id = lobby_id
		Steam.setLobbyData(lobby_id, "game_guid", GAME_GUID_FILTER)
		Steam.setLobbyData(lobby_id, "name", "Sala de " + Steam.getPersonaName())
		
		peer = SteamMultiplayerPeer.new() # Creamos el peer fresco
		var error: Error = peer.create_host(0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			_register_self_player()
			lobby_joined_success.emit() 
		else:
			print("Error fatal al crear Host: ", error)

func _on_lobby_match_list(lobbies: Array) -> void:
	search_results_updated.emit(lobbies)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1:
		current_lobby_id = lobby_id
		var host_steam_id: int = Steam.getLobbyOwner(lobby_id)
		
		if host_steam_id == Steam.getSteamID(): return
		
		peer = SteamMultiplayerPeer.new() # Creamos el peer fresco
		var error: Error = peer.create_client(host_steam_id, 0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			print("Cliente esperando conexión P2P...")

# ==========================================
# MIGRACIÓN DE HOST Y DESCONEXIONES
# ==========================================
func _on_peer_disconnected(id_red: int) -> void:
	# Alguien se fue (o lo echamos). Lo borramos de la lista visual.
	for s_id in connected_players.keys():
		if connected_players[s_id].peer_id == id_red:
			print("Jugador desconectado: ", connected_players[s_id].nombre)
			connected_players.erase(s_id)
			break
	player_list_updated.emit()

func _on_server_disconnected() -> void:
	print("El Host original se ha ido. Comprobando migración...")
	await get_tree().process_frame # Esperamos un microsegundo a que Steam asigne al nuevo dueño
	
	var nuevo_host_id = Steam.getLobbyOwner(current_lobby_id)
	
	if nuevo_host_id == Steam.getSteamID():
		print("¡Soy el nuevo Host! Migrando servidor...")
		_become_new_host()
	else:
		print("El nuevo Host es: ", nuevo_host_id, ". Reconectando...")
		_reconnect_to_new_host(nuevo_host_id)

func _become_new_host() -> void:
	var lobby_actual = current_lobby_id # Guardamos la ID del lobby porque no nos salimos de Steam
	multiplayer.multiplayer_peer = null
	
	peer = SteamMultiplayerPeer.new()
	var error = peer.create_host(0)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		_register_self_player()
		print("Ahora eres el anfitrión de la partida.")
		player_list_updated.emit()

func _reconnect_to_new_host(new_host_steam_id: int) -> void:
	multiplayer.multiplayer_peer = null
	peer = SteamMultiplayerPeer.new()
	var error = peer.create_client(new_host_steam_id, 0)
	if error == OK:
		multiplayer.multiplayer_peer = peer

# ==========================================
# GESTION DE RECURSOS (RPCs)
# ==========================================
func _register_self_player() -> void:
	var mi_id = Steam.getSteamID()
	var mi_nombre = Steam.getPersonaName()
	var mi_peer_id = multiplayer.get_unique_id() 
	
	var mi_perfil = OnlinePlayer.new()
	mi_perfil.configurar(mi_id, mi_peer_id, mi_nombre)
	
	connected_players[mi_id] = mi_perfil
	player_list_updated.emit()

func _on_peer_connected(id_red: int) -> void:
	if id_red != 1: 
		if not multiplayer.is_server() and id_red == 1:
			lobby_joined_success.emit()
		rpc_id(id_red, "request_player_info")

@rpc("authority", "reliable")
func request_player_info() -> void:
	receive_player_info.rpc(Steam.getSteamID(), Steam.getPersonaName())

@rpc("any_peer", "call_local", "reliable")
func receive_player_info(steam_id: int, persona_name: String) -> void:
	var sender_peer_id = multiplayer.get_remote_sender_id()
	
	var nuevo_jugador = OnlinePlayer.new()
	nuevo_jugador.configurar(steam_id, sender_peer_id, persona_name)
	
	connected_players[steam_id] = nuevo_jugador
	player_list_updated.emit()

# ==========================================
# FUNCIONES DE ADMINISTRACIÓN (KICK)
# ==========================================
func kick_player(target_steam_id: int) -> void:
	if not multiplayer.is_server(): return
		
	if connected_players.has(target_steam_id):
		var jugador: OnlinePlayer = connected_players[target_steam_id]
		var id_de_red = jugador.peer_id
		
		print("Expulsando a: ", jugador.nombre)
		_force_disconnect_and_leave.rpc_id(id_de_red)
		
		# Limpiamos localmente
		connected_players.erase(target_steam_id)
		multiplayer.multiplayer_peer.disconnect_peer(id_de_red)
		player_list_updated.emit()
		
		_remove_kicked_player_locally.rpc(target_steam_id)

@rpc("authority", "reliable")
func _force_disconnect_and_leave() -> void:
	print("El Host te ha expulsado de la partida.")
	if current_lobby_id > 0:
		Steam.leaveLobby(current_lobby_id)
	
	# Usamos la función central de limpieza
	cleanup_network() 
	
	get_tree().change_scene_to_file("res://Scenes/StarMenu.tscn") 

@rpc("authority", "reliable")
func _remove_kicked_player_locally(target_steam_id: int) -> void:
	if connected_players.has(target_steam_id):
		connected_players.erase(target_steam_id)
		player_list_updated.emit()

# ==========================================
# GESTIÓN DE ESTADOS (READY)
# ==========================================
@rpc("any_peer", "call_local", "reliable")
func toggle_ready_state(steam_id: int) -> void:
	if connected_players.has(steam_id):
		var jugador: OnlinePlayer = connected_players[steam_id]
		jugador.is_ready = not jugador.is_ready
		
		print(jugador.nombre, " ha cambiado su estado Ready a: ", jugador.is_ready)
		player_list_updated.emit()

		# --- NUEVA LÓGICA DE AUTO-INICIO ---
		# Solo el servidor decide si se empieza
		if multiplayer.is_server():
			if estan_todos_listos():
				print("¡Todos listos! Iniciando cuenta atrás o partida...")
				# Aquí podrías llamar directamente al inicio, 
				# pero es mejor llamar a la lógica que calcula el ganador
				_intentar_inicio_automatico()

func _intentar_inicio_automatico() -> void:
	# 1. Esperar un segundo (opcional) para que no sea un inicio brusco
	# await get_tree().create_timer(1.0).timeout 
	
	# 2. Obtenemos el ganador (puedes mover la lógica de conteo que hicimos antes aquí)
	# Suponiendo que la lógica de obtener_juego_ganador está accesible:
	var lobby_script = get_tree().current_scene # Si la escena actual es el Lobby
	if lobby_script.has_method("_obtener_juego_ganador"):
		var juego = lobby_script._obtener_juego_ganador()
		iniciar_partida_rpc.rpc(juego)

# ==========================================
# GESTIÓN DE VOTACIÓN DE MAPAS/JUEGOS
# ==========================================
signal votes_updated

# Diccionario para saber qué votó cada quién. Clave: steam_id -> Valor: nombre_del_juego
var player_votes: Dictionary = {} 
var forced_game: String = "" # Si el host fuerza un juego, se guarda aquí

@rpc("any_peer", "call_local", "reliable")
func cast_vote(steam_id: int, game_name: String) -> void:
	if forced_game != "": return 
	
	# Si el nombre del juego está vacío, significa que el jugador retiró su voto
	if game_name == "":
		player_votes.erase(steam_id)
		print("El jugador ", steam_id, " ha retirado su voto.")
	else:
		player_votes[steam_id] = game_name
		print("El jugador ", steam_id, " votó por: ", game_name)
		
	votes_updated.emit()

@rpc("authority", "call_local", "reliable")
func force_game(game_name: String) -> void:
	forced_game = game_name
	print("El Host ha forzado el juego: ", game_name)
	votes_updated.emit()

# Comprueba si todos los jugadores conectados están listos
func estan_todos_listos() -> bool:
	# Si no hay nadie, no se puede empezar
	if connected_players.is_empty(): 
		return false
	
	for s_id in connected_players:
		if not connected_players[s_id].is_ready:
			return false # En cuanto uno no esté listo, devolvemos false
			
	return true

func PlayerLeave():
	if current_lobby_id > 0:
		Steam.leaveLobby(current_lobby_id)
	cleanup_network()
	get_tree().change_scene_to_file("uid://bab52ebjkkhah")


#_____________________________________________________________________
#                  Inicio de partida
#_____________________________________________________________________
# Esta será la función que el Host llamará para que todos cambien de escena

@rpc("authority", "call_local", "reliable")
func iniciar_partida_rpc(nombre_juego: String) -> void:
	print("--- INICIANDO PARTIDA: ", nombre_juego, " ---")
	
	# 1. Definimos la ruta a la carpeta del juego
	var ruta_carpeta = "res://Games/" + nombre_juego + "/"
	var dir = DirAccess.open(ruta_carpeta)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var recurso_juego: GameClass = null
		
		# 2. Buscamos el archivo del recurso
		while file_name != "":
			if not dir.current_is_dir():
				# En juegos exportados, los recursos pueden acabar en .remap
				if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
					var ruta_archivo = ruta_carpeta + file_name.replace(".remap", "")
					var recurso_cargado = load(ruta_archivo)
					
					# 3. Comprobamos si el recurso es tu GameClass
					if recurso_cargado is GameClass:
						recurso_juego = recurso_cargado
						break # Lo encontramos, salimos del bucle
			file_name = dir.get_next()
			
		# 4. Si lo hemos encontrado, llamamos a tu método
		if recurso_juego != null:
			print("Recurso GameClass encontrado. Arrancando...")
			recurso_juego.IniciarJuego()
		else:
			print("ERROR: No se encontró ningún archivo GameClass en ", ruta_carpeta)
			
	else:
		print("ERROR: No se pudo abrir la carpeta del juego: ", ruta_carpeta)



func _physics_process(delta):if Input.is_action_just_pressed("Pausa"):AlternarPausa()

var MenuPausa=preload("uid://b8e41sk5fd26j")

func AlternarPausa():
	MenuPausa.AlternarEstado()
	
