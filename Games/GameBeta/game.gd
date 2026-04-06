extends Node
class_name Gamec

@export var Map:Mapa


func SpawnPlayer(P:OnlinePlayer):if Map != null:Map.SpawnPlayer(P)
