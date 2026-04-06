extends Node3D
class_name Root3dGame

@onready var contenedor_jugadores = $Players
var player_scene = preload("uid://bn7lxkjl8npq0")

func _ready():
	# Comprobamos si somos el Host/Servidor
	if multiplayer.is_server():
		
		# 1. Si la lista está vacía (estamos jugando solos o testeando)
		if NetworkManager.connected_players.is_empty():
			# Sacamos nuestra propia ID (1 si es ENet, o tu SteamID si es SteamMultiplayer)
			var mi_id = multiplayer.get_unique_id()
			
			# Opcional: Si usas el sistema de diccionario para los nombres que vimos antes, 
			# puedes sacar tu nombre real de Steam aquí mismo:
			if Engine.has_singleton("Steam"): # Evita errores si Steam no está inicializado
				var mi_nombre_steam = Steam.getPersonaName()
				# Lo guardamos en tu diccionario (cambia 'info_jugadores' por el nombre que uses)
				NetworkManager.connected_players[mi_id] = mi_nombre_steam
			
			# Finalmente, nos spawneamos a nosotros mismos
			spawnear_jugador(mi_id)
			
		# 2. Si la lista SÍ tiene jugadores (partida multijugador normal)
		else:
			for peer_id in NetworkManager.connected_players:
				spawnear_jugador(peer_id)

func spawnear_jugador(peer_id: int):
	var nuevo_jugador:Player3D = player_scene.instantiate()
	
	# ¡VITAL! El nombre del nodo DEBE ser el ID del jugador. 
	# Esto nos servirá luego para darle el control de ese muñeco a ese cliente específico
	nuevo_jugador.name=str(peer_id)
	if NetworkManager.connected_players[peer_id] is not String:
		nuevo_jugador.Iniciar(NetworkManager.connected_players[peer_id].nombre)
	else:nuevo_jugador.Iniciar(Steam.getPersonaName())
	
	# Lo añadimos al nodo "Jugadores" (que es el Spawn Path que configuraste)
	# Al hacer add_child aquí, el MultiplayerSpawner avisa a todos los clientes 
	# para que hagan lo mismo en sus pantallas.
	
	contenedor_jugadores.add_child(nuevo_jugador)
	nuevo_jugador.global_position.y+=2
