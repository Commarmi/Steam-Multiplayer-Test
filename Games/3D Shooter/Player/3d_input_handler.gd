extends Node

@export var P: Player3D

func _physics_process(delta):
	# 1. ¡EL ESCUDO MULTIJUGADOR!
	# Si este script se está ejecutando en el clon de otro jugador, 
	# ignoramos los inputs (hacemos un "return" para salir de la función).
	
	if not is_multiplayer_authority():
		
		return
	
	# 2. Solo el dueño real del personaje llegará a esta parte del código.
	var input_dir: Vector2 = Input.get_vector("Derecha", "Izquierda", "Abajo", "Arriva")
	var Sprinting: bool = Input.is_action_pressed("Control")
	
	P.MoveInDirection(input_dir, Sprinting, delta)
	
	if Input.is_action_just_pressed("Espacio"):
		P.Jump()
