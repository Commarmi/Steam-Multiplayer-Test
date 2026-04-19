extends Node3D
class_name Root3dGame

@onready var contenedor_jugadores = $Players
var player_scene = preload("uid://bn7lxkjl8npq0")
var NPlayers:int=0
func _ready():
	# Comprobamos si somos el Host/Servidor
	if multiplayer.is_server():
		
		# 1. Si la lista está vacía (estamos jugando solos o testeando)
		if NetworkManager.connected_players.is_empty():
			# Sacamos nuestra propia ID de red (siempre será 1 aquí)
			var mi_peer_id = multiplayer.get_unique_id()
			# Sacamos nuestro Steam ID (o inventamos uno si Steam falla)
			var mi_steam_id = 1
			if Engine.has_singleton("Steam"): 
				mi_steam_id = Steam.getSteamID()
				var mi_nombre = Steam.getPersonaName()
				
				# Creamos un OnlinePlayer temporal para que no dé error al leer el nombre
				var perfil_temp = OnlinePlayer.new()
				perfil_temp.nombre = mi_nombre
				perfil_temp.peer_id = mi_peer_id
				perfil_temp.steam_id = mi_steam_id
				NetworkManager.connected_players[mi_steam_id] = perfil_temp
			
			# Pasamos AMBAS IDs
			spawnear_jugador(mi_steam_id, mi_peer_id)
			
		# 2. Si la lista SÍ tiene jugadores (partida multijugador normal)
		else:
			for steam_id in NetworkManager.connected_players:
				# Buscamos el ID de red real guardado en tu clase OnlinePlayer
				var godot_peer_id = NetworkManager.connected_players[steam_id].peer_id
				
				# Pasamos AMBAS IDs
				spawnear_jugador(steam_id, godot_peer_id)

func spawnear_jugador(steam_id: int, godot_peer_id: int):
	var nuevo_jugador: Player3D = player_scene.instantiate()
	
	# 1. Solo le ponemos el STEAM ID como nombre
	nuevo_jugador.name = str(steam_id)
	
	# 2. Lo añadimos al mundo
	contenedor_jugadores.add_child(nuevo_jugador)
	
	nuevo_jugador.global_position.x += NPlayers * 2
	NPlayers += 1
