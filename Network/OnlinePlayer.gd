extends Resource
class_name OnlinePlayer

@export var steam_id: int = 0
@export var peer_id: int = 0 
@export var nombre: String = ""
@export var is_ready: bool = false
@export var ping: int = 0


# Una función útil para inicializarlo rápido
func configurar(s_id: int, p_id: int, nom: String) -> void:
	steam_id = s_id
	peer_id = p_id
	nombre = nom
	is_ready = false
