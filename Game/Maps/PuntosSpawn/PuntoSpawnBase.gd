@abstract
extends Node2D
class_name PuntoSpawnBase

@abstract
func IsAvailable()


func InitCode():pass

func GetPosition():
	InitCode()
	return global_position
