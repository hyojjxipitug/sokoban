extends Node

func _ready():
	pass

func _on_StartLevelButton_pressed():
	var level = get_node("Container/SpinBox").get_value()
	Globals.set("currentLevel", level)
	get_tree().get_root().get_node("/root/global").setScene("res://Level.tscn")
