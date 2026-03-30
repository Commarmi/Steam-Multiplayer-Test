class_name OnlinePlayer
extends CharacterBody2D

@export var speed: float = 300.0
@export var Daño: float = 10
var Atacando: bool


@export var Vida: float = 100:
	set(value):
		Vida = value
		if has_node("Label"):
			$Label2.text = Vida


@export var nombre: String = "":
	set(value):
		nombre = value
		if has_node("Label"):
			$Label.text = str(Vida)


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	if is_multiplayer_authority():
		nombre = Steam.getPersonaName()
	else:
		# Aseguramos que los clientes pongan el nombre si entran tarde
		if has_node("Label"):
			$Label.text = nombre
			$Label2.text = str(Vida)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var direction := Input.get_vector("Izquierda", "Derecha", "Arriva", "Abajo")
	
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
		
	if Input.is_action_just_pressed("Ataque"):
		# SOLUCIÓN 1: Calculamos el ángulo en nuestro PC local
		var angulo_ataque = global_position.angle_to_point(get_global_mouse_position())
		# Se lo pasamos por la red a todos los demás como un parámetro
		Ataque.rpc(angulo_ataque)
	
	move_and_slide()

# SOLUCIÓN 1 (cont.): Recibimos el ángulo precalculado
@rpc("any_peer", "call_local", "reliable")
func Ataque(angulo: float):
	if $Ataque/Delay.is_stopped():
		$Ataque.rotation = angulo
		Atacando = true
		$Ataque.monitoring=false
		$Ataque/TweenAnimation.play()
		$Ataque/Lifetime.start()
		$Ataque/Delay.start()

# Asumo que aquí querías poner false para volver a atacar después
func _on_lifetime_timeout():
	Atacando = false
	$Ataque.monitoring=true

# SOLUCIÓN 2: Añadimos la etiqueta @rpc para que Godot permita llamar a la función por red
@rpc("any_peer", "call_local", "reliable")
func RecibirDaño(D: float):
	# Solo el dueño de este personaje se resta su propia vida. 
	# (Recuerda poner la variable Vida en el MultiplayerSynchronizer para que el resto la vea)
	if is_multiplayer_authority():
		Vida -= D
		print(nombre, " ha recibido daño. Vida restante: ", Vida)

func _on_ataque_body_entered(body):
	# SOLUCIÓN 3: Evitar el doble daño. 
	# Si mi pantalla ve el choque de una espada que NO es mía, lo ignoro.
	if not is_multiplayer_authority():
		return
		
	if body is OnlinePlayer and body != self:
		# En vez de .rpc(), usamos .rpc_id().
		# Le enviamos el daño SOLO al ordenador del jugador dueño del personaje golpeado.
		var id_victima = body.get_multiplayer_authority()
		body.RecibirDaño.rpc_id(id_victima, Daño)
