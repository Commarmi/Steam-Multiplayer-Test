extends MarginContainer
class_name PlayerContainer


@onready var nombre_player: Button = $HBoxContainer/NombrePlayer # Asumo que es un botón para poder pulsarlo
@onready var kick: Button = $HBoxContainer/Kick
@onready var player_background: Panel = $PlayerBackground # Asumo que es un Panel o TextureRect
@onready var Ready: Panel = $HBoxContainer/MarginContainer/Panel
@onready var ready_l = $HBoxContainer/MarginContainer/ReadyL

@export var ColorNoReady: Color = Color("fc9b38")
@export var ColorReady: Color = Color("4dd559ff")
@export var ColorHost: Color = Color("45c6f0ff")

# Variable interna para saber a quién pertenece este panelcito
var mi_steam_id: int = 0

func _ready() -> void:
	# Conectamos las señales de los botones por código (así no tienes que hacerlo en el editor)
	nombre_player.pressed.connect(_on_nombre_player_pressed)
	kick.pressed.connect(_on_kick_pressed)

# ==============================================================================
# FUNCIÓN DE INICIO (El Lobby llamará a esta función al crear el panel)
# ==============================================================================
func configurar_panel(datos_jugador: OnlinePlayer, soy_el_host: bool, id_del_host_de_la_sala: int) -> void:
	mi_steam_id = datos_jugador.steam_id
	nombre_player.text = datos_jugador.nombre
	
	# 1. Configurar color de Ready / No Ready inicial
	actualizar_estado_ready(datos_jugador.is_ready)
	
	# 2. Comprobar si ESTE jugador es el host para pintarlo de azul
	if mi_steam_id == id_del_host_de_la_sala:
		player_background.modulate = ColorHost
	else:
		player_background.modulate = Color.WHITE # Color normal por defecto
		
	# 3. Mostrar botón de Kick SOLO si YO soy el host, y este panel NO es el mío
	if soy_el_host and mi_steam_id != Steam.getSteamID():
		kick.visible = true
	else:
		kick.visible = false

# ==============================================================================
# FUNCIONES DE ACTUALIZACIÓN VISUAL (Ready / Not Ready)
# ==============================================================================
func actualizar_estado_ready(esta_listo: bool) -> void:
	if esta_listo:
		Ready.modulate = ColorReady
		ready_l.text=" Ready "
	else:
		Ready.modulate = ColorNoReady
		ready_l.text=" Not Ready "

# ==============================================================================
# INTERACCIONES DE BOTONES
# ==============================================================================
func _on_nombre_player_pressed() -> void:
	# Abre el perfil de Steam del jugador en el navegador predeterminado del PC
	var url_perfil = "https://steamcommunity.com/profiles/" + str(mi_steam_id)
	OS.shell_open(url_perfil)
	print("Abriendo perfil de Steam: ", url_perfil)

func _on_kick_pressed() -> void:
	# Llamamos directamente a la función del Autoload que programamos antes
	print("Solicitando kickear a: ", nombre_player.text)
	NetworkManager.kick_player(mi_steam_id)




func _on_votar_mapa_pressed():
	pass # Replace with function body.
