extends Node2D

var Layout = ["############",
			"#..  #     ###",
			"#..  # $  $  #",
			"#..  #$####  #",
			"#..    @ ##  #",
			"#..  # #  $ ##",
			"###### ##$ $ #",
			"  # $  $ $ $ #",
			"  #    #     #",
			"  ############"]

#var Layout = ["    #####",
#			"    #   #",
#			"    #$  #",
#			"  ###  $##",
#			"  #  $ $ #",
#			"### # ## #   ######",
#			"#   # ## #####  ..#",
#			"# $  $          ..#",
#			"##### ### #@##  ..#",
#			"    #     #########",
#			"    #######"]

const NONE = -1
const WALL = 0
const FLOOR = 1
const CRATE = 2
const TARGET = 3
const PLAYER = 4

var player_pos = []
var x_max = 0
var y_max = 0

func lay_floor():
	#print ("x_max [" + str(x_max) + "]; y_max [" + str(y_max) + "]")
	var fl = get_node("FloorLayout")
	var ts = fl.get_tileset()
	var stack = [player_pos]
	
	#print ("----------------------------------------------")
	while (stack.size() > 0):
		#print ("Current stack: " + str(stack))
		var current = stack[stack.size()-1]
		stack.pop_back()
		#print ("Current tile: " + str(current))
		var x = current[0]
		var y = current[1]
		
		if fl.get_cell(x, y) == WALL or fl.get_cell(x, y) == FLOOR:
			#print ("Wall/Floor: [" + str(x) + ", " + str(y) + "] => continue")
			#print ("----------------------------------------------")
			continue
		
		#print ("Tile: [" + str(x) + ", " + str(y) + "] => not set yet")
		fl.set_cell(x, y, FLOOR)
		
		if x > 0:
			stack.append([x-1, y])
		if y > 0:
			stack.append([x, y-1])
		if x < x_max:
			stack.append([x+1, y])
		if y < y_max:
			stack.append([x, y+1])
		#print ("----------------------------------------------")

#
# This function without argument iterate on all char in the level layout. 
# Each line is considered as one row of the level
# Wall and item tiles (wall, crate, target and player) are set (wall in the floor layout tilemap, 
# items in the the items tilemap; this is needed because I have two layer: item above floor)
# Floor setup being a bit trickier it is treated in a separate dedicated function
# This function has also a second side effect, it computes the x_max and y_max needed by the next function
#
func set_walls_and_items():
	var fl = get_node("FloorLayout")
	var items = get_node("Items")
	var ts = fl.get_tileset()
	var y = 0
	for iter in Layout:
		var line = str(iter)
		var x = 0
		for index in range(line.length()):
			var char = line[index]
			var type = NONE
			if char == "#": # wall
				type = WALL
			elif char == "$": # crate
				type = CRATE
			elif char == "@": # player
				type = PLAYER
				player_pos =[x, y]
			elif char == ".": # target
				type = TARGET
			
			if type == WALL:
				fl.set_cell(x, y, WALL)
			else:
				items.set_cell(x, y, type)
			if x > x_max:
				x_max = x
			x += 1
		if y > y_max:
			y_max = y
		y += 1

func _ready():
	set_walls_and_items()
	lay_floor()
	set_process(true)

func _process(delta):
	var fl = get_node("FloorLayout")
	var ts = fl.get_tileset()
	var items = get_node("Items")
	
	#if Input.is_action_pressed("player_down") and fl.get_cell(player_pos[0], player_pos[1]) == FLOOR:
	#	



















