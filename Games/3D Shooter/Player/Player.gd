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

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/CamaraPlayer
@onready var FootCast = $FootCast
@onready var StepCast = $StepCast
var subiendo_escalon: bool = false

# --- ESTO ES NUEVO Y EVITA EL ERROR C++ ---
func _enter_tree():
	# Sacamos el Steam ID de nuestro propio nombre de nodo
	var mi_steam_id = name.to_int()
	
	# Buscamos nuestra ID de red en el diccionario y nos damos la autoridad
	if NetworkManager.connected_players.has(mi_steam_id):
		var id_de_red_real = NetworkManager.connected_players[mi_steam_id].peer_id
		set_multiplayer_authority(id_de_red_real)


# --- TU _READY DEBE QUEDAR ASÍ ---
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var peer_id = name.to_int() # (Sigue siendo el Steam ID)
	
	# Ponemos el texto de los nombres (Esto va en el ready porque 
	# los nodos hijos como $Label3D no existen en el _enter_tree aún)
	if NetworkManager.connected_players.has(peer_id):
		var nombre_real = NetworkManager.connected_players[peer_id].nombre
		$Label3D.text = nombre_real
		$Head/MeshInstance3D.mesh.text = nombre_real
	else:
		$Label3D.text = Steam.getPersonaName()
		$Head/MeshInstance3D.mesh.text = Steam.getPersonaName()
	if is_multiplayer_authority():
		# ¡Hacemos que esta cámara sea la principal solo para el dueño!
		camera.current = true
		
		# (Opcional pero recomendado) Oculta tu propio texto para no verlo flotando en tu cara
		$Label3D.visible = false 
	else:
		# Nos aseguramos de que las cámaras de los demás estén apagadas en nuestra pantalla
		camera.current = false



	# Activamos cosas solo si somos los dueños
	if is_multiplayer_authority():
		# camera.current = true
		pass



func Iniciar(Nombre:String):
	
	$Label3D.text=Nombre
	$MeshInstance3D.mesh.text=Nombre

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
