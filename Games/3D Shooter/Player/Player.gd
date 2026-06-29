extends CharacterBody3D
class_name Player3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.005

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/CamaraPlayer
@onready var FootCast = $FootCast
@onready var StepCast = $StepCast
var subiendo_escalon: bool = false
@onready var InteractCast = $Head/InteractCast

func _enter_tree():
	var mi_steam_id = name.to_int()
	
	if NetworkManager.connected_players.has(mi_steam_id):
		var id_de_red_real = NetworkManager.connected_players[mi_steam_id].peer_id
		set_multiplayer_authority(id_de_red_real)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_multiplayer_authority():
		# 1. SOY EL JUGADOR LOCAL
		camera.current = true
		$Label3D.visible = false
		
		var mi_nombre = "Jugador Local"
		if Engine.has_singleton("Steam"):
			mi_nombre = Steam.getPersonaName()
			
		# Me asigno el nombre a mí mismo
		Iniciar(mi_nombre)
		
		# Le exijo a todos los demás clientes conectados que actualicen MI nombre en sus pantallas
		rpc("SincronizarNombre", mi_nombre)
		
	else:
		# 2. ES EL CLON DE OTRO JUGADOR
		camera.current = false
		
		# Intento inicial (por si el nombre ya está en el diccionario de forma local)
		var steam_id = name.to_int()
		if NetworkManager.connected_players.has(steam_id):
			Iniciar(NetworkManager.connected_players[steam_id].nombre)
		else:
			# Ponemos un nombre temporal de carga. El RPC "SincronizarNombre" lo sobreescribirá enseguida
			Iniciar("Cargando...")

# Esta función la reciben todos los clientes a través de la red
@rpc("any_peer", "call_remote", "reliable")
func SincronizarNombre(nombre_recibido: String):
	Iniciar(nombre_recibido)

func Iniciar(Nombre: String):
	# Etiqueta estándar
	if has_node("Label3D"):
		$Label3D.text = Nombre
	
	# Manejo seguro para las mallas de texto (evita que se comparta el recurso)
	if has_node("Head/MeshInstance3D") and $Head/MeshInstance3D.mesh != null:
		$Head/MeshInstance3D.mesh = $Head/MeshInstance3D.mesh.duplicate() # <- CRUCIAL
		$Head/MeshInstance3D.mesh.text = Nombre
	elif has_node("MeshInstance3D") and $MeshInstance3D.mesh != null:
		$MeshInstance3D.mesh = $MeshInstance3D.mesh.duplicate() # <- CRUCIAL
		$MeshInstance3D.mesh.text = Nombre

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode==2:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	
	
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
func Jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func MoveInDirection(D:Vector2, Sprinting:bool, delta:float):
	if Sprinting:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
		
	var direction = (head.transform.basis * Vector3(D.x, 0, D.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	#t_bob += delta * velocity.length() * float(is_on_floor())
	#camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	#camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# --- LÓGICA DE ESCALONES ---
	# Solo calculamos el step up si nos estamos moviendo y estamos en el suelo
	if direction.length() > 0 and is_on_floor():
		aplicar_step_up(direction)
	
	move_and_slide()
func aplicar_step_up(dir: Vector3) -> void:
	# Si ya estamos en medio de la animación de subir, no calculamos otra
	if subiendo_escalon: return 
	
	var distancia_centro_a_pies = 1.0 
	var altura_mis_pies = global_position.y - distancia_centro_a_pies
	var longitud_rayo = 0.8 
	
	FootCast.target_position = FootCast.to_local(FootCast.global_position + dir * longitud_rayo)
	FootCast.force_raycast_update()
	
	if FootCast.is_colliding():
		
		# --- SOLUCIÓN 1: IGNORAR RAMPAS ---
		var normal_pared = FootCast.get_collision_normal()
		# Si la cara golpeada mira un poco hacia arriba, es una rampa. Salimos.
		if abs(normal_pared.y) > 0.05:
			return 
		
		StepCast.global_position = global_position + (dir * longitud_rayo) + Vector3(0, 0.5, 0)
		
		var destino_abajo = StepCast.global_position + Vector3(0, -2.0, 0)
		StepCast.target_position = StepCast.to_local(destino_abajo)
		StepCast.force_raycast_update()
		
		if StepCast.is_colliding():
			var punto_suelo = StepCast.get_collision_point()
			var diferencia_altura = punto_suelo.y - altura_mis_pies
			
			if diferencia_altura > 0.05 and diferencia_altura <= 0.6:
				
				# --- SOLUCIÓN 2: SUBIDA SUAVE ---
				subiendo_escalon = true # Bloqueamos para que no se vuelva loco
				
				var tween = create_tween()
				# Animamos la subida en 0.1 segundos (puedes ajustar este número)
				tween.tween_property(self, "global_position:y", global_position.y + diferencia_altura, 0.1)
				
				# Cuando el Tween termina, volvemos a permitir calcular escalones
				tween.finished.connect(func(): subiendo_escalon = false)
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func Interactuar():
	if InteractCast.is_colliding():
		var objeto_golpeado = InteractCast.get_collider()
		
		
		# 1. Comprobamos si el objeto golpeado directamente es interactuable
		if objeto_golpeado is Interactable:
			objeto_golpeado.activar.rpc()
			
		# 2. ¡AQUÍ ESTABA EL ERROR! Usamos 'elif' en lugar de 'else:if'
		elif (objeto_golpeado.get_parent()) is Interactable:
			
			objeto_golpeado.get_parent().activar.rpc()
