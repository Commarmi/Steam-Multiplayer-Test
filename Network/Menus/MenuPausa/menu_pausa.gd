extends CanvasLayer




func _on_resume_pressed():
	NetworkManager.AlternarPausa()

func _on_quit_pressed():
	NetworkManager.PlayerLeave()
	NetworkManager.AlternarPausa()

#para que no se pueda controlar voy a usar la peor solucion
#guardar i borrar temporalmente las teclas de los Input events registrados
#i antes de despausar se reccolocan pero me da palo hacerlo ahora

func AlternarEstado():
	visible=!visible
	if Input.mouse_mode==2:Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	

func _on_close_pressed():
	NetworkManager.PlayerLeave()
	get_tree().quit()
