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

# Tiles IDs used to setup floor and items tilemap
const NONE = -1
const WALL = 0
const FLOOR = 1
const CRATE = 2
const TARGET = 3
const PLAYER = 4

# Direction constants
const UP = 0
const RIGHT = 1
const DOWN = 2
const LEFT = 3

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
	var initItems = get_node("InitialItems")
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
				player_pos = [x, y]
			elif char == ".": # target
				type = TARGET
			
			if type == WALL:
				fl.set_cell(x, y, WALL)
			else:
				items.set_cell(x, y, type)
				initItems.set_cell(x, y, type) # this copy will not be modified and will hold places of the target
			if x > x_max:
				x_max = x
			x += 1
		if y > y_max:
			y_max = y
		y += 1

func _ready():
	set_walls_and_items()
	lay_floor()
	set_process_input(true)

func _input(event):
	var fl = get_node("FloorLayout")
	var ts = fl.get_tileset()
	var items = get_node("Items")
	
	var origin = get_node("InitialItems").get_cell(player_pos[0], player_pos[1])
	if origin != TARGET:
		origin = NONE
	
	if event.is_action_released("player_down") and is_move_possible(player_pos, DOWN):
		#print ("input player down")
		# remove character from old location
		get_node("Items").set_cell(player_pos[0], player_pos[1], origin)
		# update game state
		player_pos[1] += 1
		# push box if needed
		if items.get_cell(player_pos[0], player_pos[1]) == CRATE:
			items.set_cell(player_pos[0], player_pos[1]+1, CRATE)
	
	if event.is_action_released("player_up") and is_move_possible(player_pos, UP):
		#print ("input player up")
		# remove character from old location
		get_node("Items").set_cell(player_pos[0], player_pos[1], origin)
		# update game state
		player_pos[1] -= 1
		# push box if needed
		if items.get_cell(player_pos[0], player_pos[1]) == CRATE:
			items.set_cell(player_pos[0], player_pos[1]-1, CRATE)
	
	if event.is_action_released("player_right") and is_move_possible(player_pos, RIGHT):
		#print ("input player right")
		# remove character from old location
		get_node("Items").set_cell(player_pos[0], player_pos[1], origin)
		# update game state
		player_pos[0] += 1
		# push box if needed
		if items.get_cell(player_pos[0], player_pos[1]) == CRATE:
			items.set_cell(player_pos[0]+1, player_pos[1], CRATE)
	
	if event.is_action_released("player_left") and is_move_possible(player_pos, LEFT):
		#print ("input player left")
		# remove character from old location
		get_node("Items").set_cell(player_pos[0], player_pos[1], origin)
		# update game state
		player_pos[0] -= 1
		# push box if needed
		if items.get_cell(player_pos[0], player_pos[1]) == CRATE:
			items.set_cell(player_pos[0]-1, player_pos[1], CRATE)
	
	# move char sprite in the destination
	get_node("Items").set_cell(player_pos[0], player_pos[1], PLAYER)


func is_move_possible(origin, direction, move_crate=false):
	if direction < 0 or direction > 3:
		return false # invalid argument
	var destination = [origin[0], origin[1]]
	if direction == UP:
		destination[1] -= 1
	elif direction == RIGHT:
		destination[0] += 1
	elif direction == DOWN:
		destination[1] += 1
	elif direction == LEFT:
		destination[0] -= 1
	if destination[0] < 0 or destination[0] > x_max:
		return false # cannot move outside of the game area
	if destination[1] < 0 or destination[1] > x_max:
		return false # cannot move outside of the game area
	if get_node("FloorLayout").get_cell(destination[0], destination[1]) == WALL:
		return false # cannot move into a wall
	if move_crate and get_node("Items").get_cell(destination[0], destination[1]) == CRATE:
		return false # cannot move a crate in another crate
	if get_node("Items").get_cell(destination[0], destination[1]) == CRATE and not is_move_possible(destination, direction, true):
		# check if the crate itself can be moved in the same direction and doesn't hit another crate
		return false # destination crate cannot be moved
	#if all other test succeeded, move allowed
	return true

















