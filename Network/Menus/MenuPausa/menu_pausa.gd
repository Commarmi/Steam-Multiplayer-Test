extends CanvasLayer




func _on_resume_pressed():
	NetworkManager.AlternarPausa()

func _on_quit_pressed():
	NetworkManager.PlayerLeave()
	NetworkManager.AlternarPausa()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#para que no se pueda controlar voy a usar la peor solucion
#guardar i borrar temporalmente las teclas de los Input events registrados
#i antes de despausar se reccolocan pero me da palo hacerlo ahora
# Guardamos el modo exacto del ratón (es un número entero) en lugar de un booleano
var ultimo_modo_raton: int = Input.MOUSE_MODE_VISIBLE

func AlternarEstado():
	if not visible:
		# EL MENÚ SE VA A ABRIR
		# 1. Guardamos cómo estaba el ratón en el juego
		ultimo_modo_raton = Input.mouse_mode
		# 2. Liberamos el ratón para poder hacer clic en los botones
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# 3. Mostramos el menú
		visible = true
		
	else:
		# EL MENÚ SE VA A CERRAR
		# 1. Restauramos el ratón exactamente a como estaba antes
		Input.set_mouse_mode(ultimo_modo_raton)
		# 2. Ocultamos el menú
		visible = false
		
	# Un print limpio para que veas qué está pasando en la consola
	prints("Modo de ratón guardado:", ultimo_modo_raton, " | Menú visible:", visible)
	

func _on_close_pressed():
	NetworkManager.PlayerLeave()
	get_tree().quit()
