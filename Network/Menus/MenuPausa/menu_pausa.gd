extends CanvasLayer




func _on_resume_pressed():
	NetworkManager.AlternarPausa()

func _on_quit_pressed():
	NetworkManager.PlayerLeave()
	NetworkManager.AlternarPausa()

#para que no se pueda controlar voy a usar la peor solucion
#guardar i borrar temporalmente las teclas de los Input events registrados
#i antes de despausar se reccolocan pero me da palo hacerlo ahora
var UltimoEstado:bool
func AlternarEstado():
	
	if visible==false:
		UltimoEstado=Input.mouse_mode==Input.MOUSE_MODE_VISIBLE
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		if UltimoEstado==false :Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visible=!visible
	prints(UltimoEstado,visible==false)
	

func _on_close_pressed():
	NetworkManager.PlayerLeave()
	get_tree().quit()
