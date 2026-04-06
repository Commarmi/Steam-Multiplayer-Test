extends Node2D
class_name Mapa

var PuntosSpawn:Array[PuntoSpawnBase]


func _ready():
	for N in get_children():if N is PuntoSpawnBase:PuntosSpawn.append(N)

func SpawnPlayer(P:OnlinePlayerBeta):
	add_child(P)
	P.global_position=FindSpawn()



func FindSpawn()->Vector2:
	for I in PuntosSpawn:if I.IsAvailable():return I.GetPosition()
	return global_position
