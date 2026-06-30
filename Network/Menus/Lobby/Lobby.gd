extends PanelContainer
class_name Lobby

# ==============================================================================
# REFERENCIAS DE LA UI
# ==============================================================================
# Eliminado el %HostPick de la lista

# Referencias de Jugadores
@onready var player_list = $MarginContainer/VBoxContainer/MainRow/PlayersContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/PlayerList
@onready var player_container_template = $MarginContainer/VBoxContainer/MainRow/PlayersContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/PlayerContainer


# Referencias del Selector de Juegos
const DireccionCarpetaJuegos: String = "res://Games/"
@onready var game_list = $MarginContainer/VBoxContainer/MainRow/GameSelecotrMenu/MarginContainer/ScrollContainer/VBoxContainer/GameList
@onready var InitialGameContainer = $MarginContainer/VBoxContainer/MainRow/GameSelecotrMenu/MarginContainer/ScrollContainer/VBoxContainer/GameContainer

# Textos e Info
@onready var loby_name = %LobyName
@onready var ping = %Ping

var available_games: PackedStringArray = []
var game_button_group := ButtonGroup.new()

# ==============================================================================
# INICIALIZACIÓN
# ==============================================================================
func _ready() -> void:
	# Ocultamos las plantillas
	player_container_template.visible = false
	InitialGameContainer.visible = false 

	NetworkManager.votes_updated.connect(actualizar_lista_juegos) 
	
	# Comprobamos permisos de Host
	
	var soy_host = multiplayer.is_server()
	# Textos informativos
	if NetworkManager.current_lobby_id > 0:
		loby_name.text = Steam.getLobbyData(NetworkManager.current_lobby_id, "name")
		
	if soy_host:
		ping.text = "Ping: 0ms (Host)"
	else:
		ping.text = "Ping: Conectado al Host"
		
	# Cargar carpetas y dibujar las listas por primera vez
	_cargar_juegos_desde_carpeta()
	actualizar_lista_juegos()

func _cargar_juegos_desde_carpeta() -> void:
	if DirAccess.dir_exists_absolute(DireccionCarpetaJuegos):
		available_games = DirAccess.get_directories_at(DireccionCarpetaJuegos)
	else:
		print("La carpeta de juegos no existe en la ruta: ", DireccionCarpetaJuegos)

# ==============================================================================
# 1. ACTUALIZAR LISTA DE JUEGOS
# ==============================================================================
func actualizar_lista_juegos() -> void:
	if multiplayer.multiplayer_peer == null: return
		
	for child in game_list.get_children():
		child.queue_free()
		
	game_button_group = ButtonGroup.new()
	game_button_group.allow_unpress = true
		
	var recuento_votos: Dictionary = {}
	for game in available_games:
		recuento_votos[game] = 0
		
	for steam_id in NetworkManager.player_votes:
		var juego_votado = NetworkManager.player_votes[steam_id]
		if recuento_votos.has(juego_votado):
			recuento_votos[juego_votado] += 1
			
	var max_votos = 0
	for votos in recuento_votos.values():
		if votos > max_votos:
			max_votos = votos
			
	var mi_id = Steam.getSteamID()
	var mi_voto = ""
	if NetworkManager.player_votes.has(mi_id):
		mi_voto = NetworkManager.player_votes[mi_id]
		
	# Mantenemos esto por si el Host lo fuerza de otra forma, pero no afecta sin el botón
	var is_any_forced = (NetworkManager.forced_game != "")
	
	for game_name in available_games:
		var votos_de_este_juego = recuento_votos[game_name]
		var is_winning = (votos_de_este_juego == max_votos and max_votos > 0)
		var is_forced = (NetworkManager.forced_game == game_name)
		
		var am_i_voting_this = (mi_voto == game_name)
		
		var nuevo_panel = InitialGameContainer.duplicate()
		nuevo_panel.visible = true
		game_list.add_child(nuevo_panel)
		
		nuevo_panel.configurar_juego(game_name, votos_de_este_juego, is_winning, is_forced, am_i_voting_this, is_any_forced, game_button_group)


# ==============================================================================
# BOTONES DE LA INTERFAZ
# ==============================================================================
func _on_ready_button_pressed() -> void:
	var mi_id = Steam.getSteamID()
	NetworkManager.toggle_ready_state.rpc(mi_id)

func _on_kick_all_pressed() -> void:
	if not multiplayer.is_server(): return
	var mi_id = Steam.getSteamID()
	
	for s_id in NetworkManager.connected_players.keys():
		if s_id != mi_id:
			NetworkManager.kick_player(s_id)

func _on_quit_buton_pressed() -> void:NetworkManager.PlayerLeave()




func _on_start_host_pressed() -> void:
	if not multiplayer.is_server(): return
	
	if NetworkManager.estan_todos_listos():
		# 1. Calculamos qué juego ha ganado
		var juego_ganador = _obtener_juego_ganador()
		
		# 2. Seguridad: si por algún motivo no hay juego, no empezamos
		if juego_ganador == "":
			print("Error: No se puede iniciar porque no hay ningún juego seleccionado.")
			return
			
		# 3. AHORA SÍ: Llamamos al RPC pasándole el nombre del juego
		NetworkManager.iniciar_partida_rpc.rpc(juego_ganador)
	else:
		print("No se puede empezar: faltan jugadores por confirmar.")

# ==============================================================================
# LÓGICA PARA DECIDIR EL GANADOR
# ==============================================================================
func _obtener_juego_ganador() -> String:
	# 1. Si el Host forzó un juego, ese gana automáticamente ignorando los votos
	if NetworkManager.forced_game != "":
		return NetworkManager.forced_game
		
	# 2. Si no, contamos los votos del NetworkManager
	var recuento_votos = {}
	for voto in NetworkManager.player_votes.values():
		if recuento_votos.has(voto):
			recuento_votos[voto] += 1
		else:
			recuento_votos[voto] = 1
			
	# 3. Buscamos cuál tiene la mayor cantidad de votos
	var ganador_actual = ""
	var max_votos = 0
	
	for juego in recuento_votos.keys():
		if recuento_votos[juego] > max_votos:
			max_votos = recuento_votos[juego]
			ganador_actual = juego
			
	# 4. Si nadie votó (o hubo un error raro), elegimos el primer juego disponible por defecto
	if ganador_actual == "" and available_games.size() > 0:
		print("Nadie votó. Eligiendo el juego por defecto...")
		ganador_actual = available_games[0]
		
	return ganador_actual
