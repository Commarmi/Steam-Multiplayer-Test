@abstract
extends Node3D
class_name PuntoSpawnBase3D

@abstract
func IsAvailable()

@rpc("any_peer", "call_local", "reliable")
func InitCode():pass

func GetPosition():
	InitCode.rpc()
	return global_position
