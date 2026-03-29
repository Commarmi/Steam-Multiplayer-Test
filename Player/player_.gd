class_name OnlinePlayer
extends CharacterBody2D

@export var speed: float = 300.0
@export var Vida:float=100


func _enter_tree() -> void:
	# Establecemos la autoridad basándonos en el nombre del nodo.
	# El MultiplayerSpawner (que haremos luego) nombrará este nodo con tu Steam ID.
	set_multiplayer_authority(name.to_int())

@export var nombre: String = "":
	set(value):
		nombre = value
		# Comprobamos que el Label exista en el árbol para evitar errores al instanciar
		if has_node("Label"):
			$Label.text = nombre

func _ready():
	if is_multiplayer_authority():
		nombre = Steam.getPersonaName()

func _physics_process(delta: float) -> void:
	# Si este cliente no es el dueño de este personaje, ignoramos sus inputs locales.
	# El MultiplayerSynchronizer se encargará de moverlo en esta pantalla.
	
	if not is_multiplayer_authority():
		return

	# Solo el dueño ejecuta este código y mueve el personaje sin latencia.
	var direction := Input.get_vector("Izquierda", "Derecha", "Arriva", "Abajo")
	
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
