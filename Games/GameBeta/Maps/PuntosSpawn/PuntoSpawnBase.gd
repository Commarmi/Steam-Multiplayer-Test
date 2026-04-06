@abstract
extends Node2D
class_name PuntoSpawnBase

@abstract
func IsAvailable()

@rpc("any_peer", "call_local", "reliable")
func InitCode():pass

func GetPosition():
	InitCode.rpc()
	return global_position
