extends Node

func _ready():
	get_node("Container/SpinBox").set_value(Globals.get("currentLevel")+1)

func _on_StartLevelButton_pressed():
	var level = get_node("Container/SpinBox").get_value()
	Globals.set("currentLevel", level-1)
	get_tree().get_root().get_node("/root/global").setScene("res://Level.tscn")
