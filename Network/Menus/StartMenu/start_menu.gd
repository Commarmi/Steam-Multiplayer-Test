extends MarginContainer
class_name StarMenu

@onready var match_holder = %MatchHolder
@onready var label = $PanelContainer/VBoxContainer/Label

# Exportamos la escena del lobby para arrastrarla en el inspector
@export var lobby_scene: PackedScene 

func _ready() -> void:
	# Escuchamos los resultados de búsqueda
	NetworkManager.search_results_updated.connect(_on_search_results_received)
	label.text=Steam.getPersonaName()
	# Escuchamos cuando la conexión a la sala es exitosa para cambiar de escena
	NetworkManager.lobby_joined_success.connect(_go_to_lobby)

func _on_host_pressed() -> void:
	NetworkManager.start_hosting()

func _on_search_pressed() -> void:
	# Limpiamos resultados anteriores
	for child in match_holder.get_children():
		child.queue_free()
		
	NetworkManager.start_searching()

func _on_search_results_received(lobbies: Array) -> void:
	for lobby_id in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby_id, "name")
		
		if lobby_name == "":
			lobby_name = "Sala desconocida"
			
		var btn := Button.new()
		btn.text = lobby_name
		btn.pressed.connect(NetworkManager.join_lobby_by_id.bind(lobby_id))
		
		match_holder.add_child(btn)

func _go_to_lobby() -> void:
	if lobby_scene != null:
		# Cambiamos de escena. ¡El diccionario está a salvo en el NetworkManager!
		get_tree().change_scene_to_packed(lobby_scene)
	else:
		push_error("ERROR: No has asignado la escena del Lobby en el inspector de StarMenu")
