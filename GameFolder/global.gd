extends Node

const LEVELS_FILE = "res://Original.txt"
var levels = []
var currentScene = null

func _ready():
	#On load set the current scene to the last scene available
	currentScene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() -1)
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


# This function switches to the target scene 
func setScene(path):
   #clean up the current scene
   currentScene.queue_free()
   #load the file passed in as the param "path"
   var s = ResourceLoader.load(path)
   #create an instance of our scene
   currentScene = s.instance()
   # add scene to root
   get_tree().get_root().add_child(currentScene)
