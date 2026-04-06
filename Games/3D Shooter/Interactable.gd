#@abstract
@tool # Permite que este código funcione dentro del editor de Godot
extends Node3D
class_name Interactable

# Al arrastrar un nodo, avisamos al editor para que actualice la lista del desplegable
@export var nodo_objetivo: Node:
	set(value):
		nodo_objetivo = value
		notify_property_list_changed() 

# Esta variable guardará el texto, pero la ocultaremos para mostrar el desplegable en su lugar
var nombre_del_metodo: String = ""

# Esta función de Godot nos permite crear propiedades personalizadas en el Inspector
func _get_property_list() -> Array:
	var properties = []
	var opciones_dropdown = ""
	
	if is_instance_valid(nodo_objetivo):
		# Obtenemos todas las funciones del nodo que hemos arrastrado
		var metodos = nodo_objetivo.get_method_list()
		for m in metodos:
			# Filtramos para no mostrar funciones internas del motor (las que empiezan por "_")
			if not m.name.begins_with("_"):
				opciones_dropdown += m.name + ","
	
	# Creamos el menú desplegable (Enum)
	properties.append({
		"name": "nombre_del_metodo",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": opciones_dropdown
	})
	
	return properties

# Tu función para llamar desde fuera
func activar() -> void:
	# Evitamos que se ejecute si estamos tocando cosas en el editor
	if Engine.is_editor_hint(): 
		return 
		
	if is_instance_valid(nodo_objetivo) and not nombre_del_metodo.is_empty():
		if nodo_objetivo.has_method(nombre_del_metodo):
			nodo_objetivo.call(nombre_del_metodo)
