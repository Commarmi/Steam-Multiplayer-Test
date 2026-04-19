extends CanvasLayer


@onready var FPSLable = $MarginContainer/HBoxContainer/FPSLable
@onready var PingLable = $MarginContainer/HBoxContainer/PingLable


func _process(delta):
	FPSLable.set_text("FPS " + str(Engine.get_frames_per_second()))
	
