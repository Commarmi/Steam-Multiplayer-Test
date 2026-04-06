extends MarginContainer
class_name GameSelectorOption

@onready var selected_l = $HBoxContainer/MarginContainer/SelectedL
@onready var boton_votar = $HBoxContainer/VotarMapa
@onready var Fondo = $HBoxContainer/MarginContainer/Panel

@export var ColorNormal: Color = Color("fc9b38")
@export var ColorReady: Color = Color("4dd559ff")
@export var ColorHost: Color = Color("45c6f0ff")

var mi_nombre_juego: String = ""

func configurar_juego(game_name: String, num_votos: int, is_winning: bool, is_forced: bool, am_i_voting_this: bool, is_any_forced: bool, btn_group: ButtonGroup) -> void:
	mi_nombre_juego = game_name
	boton_votar.text = game_name
	selected_l.text = str(num_votos)
	
	# Configuramos el Toggle y el Grupo
	boton_votar.toggle_mode = true
	boton_votar.button_group = btn_group
	
	# Marcamos sin disparar señales
	boton_votar.set_pressed_no_signal(am_i_voting_this)
	
	# Si el Host forzó un juego, nadie puede tocar los botones
	boton_votar.disabled = is_any_forced
	
	# Coloreamos el marcador
	if is_forced:
		Fondo.modulate = ColorHost
	elif is_winning:
		Fondo.modulate = ColorReady
	else:
		Fondo.modulate = ColorNormal

func _on_votar_mapa_pressed() -> void:
	# Verificamos el estado actual del botón después de haber hecho clic
	if boton_votar.button_pressed:
		NetworkManager.cast_vote.rpc(Steam.getSteamID(), mi_nombre_juego)
	else:
		# Lo hemos despulsado
		NetworkManager.cast_vote.rpc(Steam.getSteamID(), "")
