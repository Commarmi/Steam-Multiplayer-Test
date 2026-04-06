extends Resource
class_name GameClass

@export var RootSceen:PackedScene


func IniciarJuego():
	if RootSceen==null:push_error("Cargado juego sin escena root asignada | Nombre:"+str(self))
	NetworkManager.get_tree().change_scene_to_packed(RootSceen)
