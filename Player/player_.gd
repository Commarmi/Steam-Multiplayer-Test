class_name OnlinePlayer
extends CharacterBody2D

@export var speed: float = 300.0
@export var Vida:float=100
@export var Daño:float=10
var Atacando:bool


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
	if Input.is_action_just_pressed("Ataque"):Ataque.rpc()
	
	move_and_slide()

@rpc("any_peer", "call_local", "reliable")
func Ataque():
	print("Atacando")
	if $Ataque/Delay.is_stopped():
		$Ataque.rotation=global_position.angle_to_point(get_global_mouse_position())
		Atacando=true
		$Ataque/TweenAnimation.play()
		$Ataque/Lifetime.start()
		$Ataque/Delay.start()


func _on_lifetime_timeout():
	Atacando=true

	

func RecibirDaño(D:float):
	Vida-=D


func _on_ataque_body_entered(body):
	if body is OnlinePlayer and body!=self:RecibirDaño.rpc(Daño)
