extends CSGCombiner3D

@export var VelocidadGiro:Vector3=Vector3(0,1,0)

func _process(delta):
	rotation+=VelocidadGiro*delta
	
