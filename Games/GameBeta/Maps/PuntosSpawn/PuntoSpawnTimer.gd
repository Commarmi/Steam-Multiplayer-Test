extends PuntoSpawnBase
class_name PuntoSpawnTimer

var T:Timer
@export var SpawnDelay:float=10

func _ready():
	T=Timer.new()
	T.one_shot=true
	T.wait_time=SpawnDelay
	add_child(T)

func IsAvailable():
	return T.is_stopped()

func InitCode():
	T.start()
