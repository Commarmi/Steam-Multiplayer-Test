extends PuntoSpawnBase3D
class_name PuntoSpawnTimer3D

var T:Timer
@export var SpawnDelay:float=10

func _ready():
	T=Timer.new()
	T.one_shot=true
	T.wait_time=SpawnDelay
	T.stop()
	add_child(T)

 


func IsAvailable():
	return T.is_stopped()

func InitCode():
	T.start()
