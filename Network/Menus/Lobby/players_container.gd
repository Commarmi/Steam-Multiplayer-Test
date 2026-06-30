extends MarginContainer
class_name PlayersContainer

@onready var n_players = %NPlayers
@onready var player_list = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/PlayerList
@onready var player_container_template = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/PlayerContainer
@onready var kick_all = %KickAll




func _ready():
	
	NetworkManager.player_list_updated.connect(actualizar_lista_jugadores)
	var soy_host = multiplayer.is_server()
	kick_all.visible=soy_host
	actualizar_lista_jugadores()


# ==============================================================================
# LÓGICA DE JUGADORES
# ==============================================================================
func actualizar_lista_jugadores() -> void:
	# Seguridad
	if multiplayer.multiplayer_peer == null:
		n_players.text = "0"
		return

	for child in player_list.get_children():
		child.queue_free()
	
	var id_del_host = Steam.getLobbyOwner(NetworkManager.current_lobby_id)
	var soy_host = multiplayer.is_server()
	
	n_players.text = str(NetworkManager.connected_players.size())
	
	for steam_id in NetworkManager.connected_players:
		var datos_jugador: OnlinePlayer = NetworkManager.connected_players[steam_id]
		
		var nuevo_panel = player_container_template.duplicate()
		nuevo_panel.visible = true 
		player_list.add_child(nuevo_panel)
		
		nuevo_panel.configurar_panel(datos_jugador, soy_host, id_del_host)
