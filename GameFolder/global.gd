extends Node

const LEVELS_FILE = "res://Original.txt"
var levels = []

func _ready():
	var f = File.new()
	f.open(LEVELS_FILE, File.READ)
	
	var inLevel = false
	var line = f.get_line()
	var level = []
	
	while not f.eof_reached():
		if not inLevel:
			if not line == "" and line.find(";") == -1:
				# this is the startup of a new level description
				inLevel = true
		
		if inLevel:
			if line == "" or line.find(";") != -1:
				# this is the end of the current level description
				levels.append(level)
				level = []
				inLevel = false
			else:
				# this is the next line of the level description
				level.append(line)
		
		line = f.get_line()
	f.close()
	
	Globals.set("currentLevel", 0)
