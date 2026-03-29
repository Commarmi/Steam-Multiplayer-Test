extends Node
class_name Game

@export var Map:Mapa


func SpawnPlayer(P:OnlinePlayer):if Map != null:Map.SpawnPlayer(P)
