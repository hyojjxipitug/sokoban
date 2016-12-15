extends Node2D

#------------------------------------------------------------------------------------------------------
# Member variables section
#------------------------------------------------------------------------------------------------------

# layout of the floor from input file. The variable holds an array of strings that will be iterated to setup level
var Layout = [] 
# holds the number of steps done at any point in game
var step_count = 0
# holds the elapsed time at any point in game
var elapsed_time = 0
# holds the current player position
var player_pos = []
# holds the list of all target cells. The variable will hold an array of arrays, each one being a position
var targets = []
# number of rows in level
var x_max = 0
# number of columns in level
var y_max = 0
# this variables holds the list of moves for the undo/redo functionality
# the stack will hold values under the form [Direction (see constants section), bool crate moved]
var undo_stack = []
# stack pointer needed to allow redo specifically. Initialized at -1 as it will be incremented for each step
var undo_stack_pointer = -1

#------------------------------------------------------------------------------------------------------
# Constants section
#------------------------------------------------------------------------------------------------------

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

#------------------------------------------------------------------------------------------------------
# Methods section - Level setup
#------------------------------------------------------------------------------------------------------

# initialization retrieves the level from Global dictionary, then loads the correct level description 
# from global auto-loaded node in scene tree and then processes it.
func _ready():
	var level = Globals.get("currentLevel")
	Layout = get_tree().get_root().get_node("/root/global").levels[level]
	get_node("Title").set_text(str("SOKOBAN - Level ", level+1))
	set_walls_and_items()
	lay_floor()
	set_process_input(true)

# This function without argument iterate on all char in the level layout. 
# Each line is considered as one row of the level
# Wall and item tiles (wall, crate, target and player) are set (wall in the floor layout tilemap, 
# items in the the items tilemap; this is needed because I have two layers: items above floor)
# Floor setup being a bit trickier it is treated in a separate dedicated function
# This function has also a second side effect, it computes the x_max and y_max needed by the 
# function lay_floor
func set_walls_and_items():
	var fl = get_node("LevelContent/FloorLayout")
	var items = get_node("LevelContent/Items")
	var initItems = get_node("LevelContent/InitialItems")
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
				targets.append([x, y])
			
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

# This function used to place the floor tiles is separated from the function set_walls_and_items
# because I cannot determine from the input if a space is a floor tile inside the level or an empty 
# space outside the level. The algorithm is a graph traversal going from floor tile to floor tile starting
# from the original player position. Note that I implemented it with a while loop around a stack of node 
# in the graph to visit in order to avoid potential stack overflow if done with recursion
func lay_floor():
	var fl = get_node("LevelContent/FloorLayout")
	var ts = fl.get_tileset()
	var stack = [player_pos]
	
	while (stack.size() > 0):
		var current = stack[stack.size()-1] # current tile being visited
		stack.pop_back() # pop_back does NOT return the removed element, hence I get it on previous line
		#print ("Current tile: " + str(current))
		var x = current[0]
		var y = current[1]
		
		if fl.get_cell(x, y) == WALL or fl.get_cell(x, y) == FLOOR:
			# if the tile is either a wall or a floor we stop processing this node
			continue
		
		# since we ensured we could put a floor tile, it is done on next line
		fl.set_cell(x, y, FLOOR)
		
		# add to the stack of nodes to process the neighbours (if within boundaries)
		if x > 0:
			stack.append([x-1, y])
		if y > 0:
			stack.append([x, y-1])
		if x < x_max:
			stack.append([x+1, y])
		if y < y_max:
			stack.append([x, y+1])

#------------------------------------------------------------------------------------------------------
# Methods section - Game loop for this level
#------------------------------------------------------------------------------------------------------

# this functions executes the actual move of the player on screen + game states
# /!\ Attention, no validation whatsoever is executed
# the function also pushes crate if needed
# optional parameter update_stack is used to explicitely ask not to add anything to the undo stack.
# This is needed to allow the undo/redo functionality to reuse the move_player method
func move_player(direction, update_stack=true):
	var items = get_node("LevelContent/Items")
	var origin = get_node("LevelContent/InitialItems").get_cell(player_pos[0], player_pos[1])
	if origin != TARGET: # only re-establish target sprites
		origin = NONE
	# remove character from old location
	get_node("LevelContent/Items").set_cell(player_pos[0], player_pos[1], origin)
	# update game state based on direction
	var crate_pos = [player_pos[0], player_pos[1]]
	if direction == DOWN:
		player_pos[1] += 1
		crate_pos[1] += 2
	elif direction == UP:
		player_pos[1] -= 1
		crate_pos[1] -= 2
	if direction == RIGHT:
		player_pos[0] += 1
		crate_pos[0] += 2
	elif direction == LEFT:
		player_pos[0] -= 1
		crate_pos[0] -= 2
	
	var crate_moved = false
	# push box if needed
	if items.get_cell(player_pos[0], player_pos[1]) == CRATE:
		crate_moved = true
		items.set_cell(crate_pos[0], crate_pos[1], CRATE)
	# update steps count
	step_count += 1
	get_node("StepsCount").set_text(str("Steps : ", step_count))
	
	# handle undo_stack
	if update_stack:
		while undo_stack.size() - 1 > undo_stack_pointer:
			undo_stack.pop_back() # remove previous steps undone and replace by new one
		undo_stack.append([direction, crate_moved])
		undo_stack_pointer += 1
	
	# move char sprite in the destination
	get_node("LevelContent/Items").set_cell(player_pos[0], player_pos[1], PLAYER)
	if is_game_over():
		on_game_over()

# This method reacts to player moves action as defined in inputmap. After checking that the player is
# actually moving and that he's allowed to go in that direction (taking crates into account),
# the method calls the move_player method
func _input(event):
	var fl = get_node("LevelContent/FloorLayout")
	var ts = fl.get_tileset()
	var items = get_node("LevelContent/Items")
	
	var origin = get_node("LevelContent/InitialItems").get_cell(player_pos[0], player_pos[1])
	if origin != TARGET:
		origin = NONE
	
	if event.is_action_released("player_down") and is_move_possible(player_pos, DOWN):
		move_player(DOWN)
	
	if event.is_action_released("player_up") and is_move_possible(player_pos, UP):
		move_player(UP)
	
	if event.is_action_released("player_right") and is_move_possible(player_pos, RIGHT):
		move_player(RIGHT)
	
	if event.is_action_released("player_left") and is_move_possible(player_pos, LEFT):
		move_player(LEFT)

# This method verifies that the move requested by the player is a legal one by checking 
# first all reasons to deny the move. If move_crate is set to true, it will check if the 
# crate located on the landing cell can be pushed further. This mode is used the method itself
# via recursion and is transparent to the caller
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
	if get_node("LevelContent/FloorLayout").get_cell(destination[0], destination[1]) == WALL:
		return false # cannot move into a wall
	if move_crate and get_node("LevelContent/Items").get_cell(destination[0], destination[1]) == CRATE:
		return false # cannot move a crate in another crate
	if get_node("LevelContent/Items").get_cell(destination[0], destination[1]) == CRATE and not is_move_possible(destination, direction, true):
		# check if the crate itself can be moved in the same direction and doesn't hit another crate
		return false # destination crate cannot be moved
	#if all other test succeeded, move allowed
	return true

#------------------------------------------------------------------------------------------------------
# Methods section - Undo/Redo handling
#------------------------------------------------------------------------------------------------------

# undo last move from stack. Note that this count as step :-)
func undo_move():
	if undo_stack_pointer < 0:
		return # nothing to undo, stack is empty
	
	var last = undo_stack[undo_stack_pointer]
	# undo_stack.pop_back() # I do not popback the last element to be able to have the redo functionality
	
	var new_crate_pos = [player_pos[0],player_pos[1]] 
	var old_crate_pos = [player_pos[0],player_pos[1]] # location at which I will later remove the crate
	
	# determine in which direction to move the player
	var direction = last[0]
	if direction == UP:
		direction = DOWN
		old_crate_pos[1] -= 1 
	elif direction == DOWN:
		direction = UP
		old_crate_pos[1] += 1 
	elif direction == LEFT:
		direction = RIGHT
		old_crate_pos[0] -= 1 
	elif direction == RIGHT:
		direction = LEFT
		old_crate_pos[0] += 1 
	
	if last[1]: # remove crate from current position
		get_node("LevelContent/Items").set_cell(old_crate_pos[0],old_crate_pos[1], NONE)
	
	undo_stack_pointer -= 1 # goes one step back in the stack
	move_player(direction, false)
	
	if last[1]: # a crate has been moved and must be reverted back
		get_node("LevelContent/Items").set_cell(new_crate_pos[0],new_crate_pos[1], CRATE)

# This functions re-excute the last move undone
func redo_move():
	if undo_stack_pointer >= undo_stack.size() - 1:
		return # nothing to do, stack pointer already pointing to the top of the stack, 
		       # meaning there is nothing to redo
	
	undo_stack_pointer += 1
	var last = undo_stack[undo_stack_pointer]
	move_player(last[0], false)

#------------------------------------------------------------------------------------------------------
# Methods section - Game over handling
#------------------------------------------------------------------------------------------------------

# check if the game is finished succesfully
func is_game_over():
	var items = get_node("LevelContent/Items")
	for target in targets:
		# verify that all target cells are covered by a crate or return false
		if items.get_cell(target[0], target[1]) != CRATE:
			return false
	# all targets were checked succesfully
	return true

# congratulate the player for a finished level
func on_game_over():
	get_node("Timer").stop()
	set_process_input(false)
	var level = Globals.get("currentLevel") + 1
	var details = "\n\nYou finished level %d in %d steps and %d seconds\n\n\n" % [level, step_count, elapsed_time]
	get_node("Congrats/VBoxContainer/CongratsDetails").set_text(details)
	get_node("Congrats").show()


#------------------------------------------------------------------------------------------------------
# Methods section - Event listening connections
#------------------------------------------------------------------------------------------------------

# update elapsed time label every second
func _on_Timer_timeout():
	elapsed_time += 1
	get_node("ElapsedTime").set_text(str("Elapsed time : ", elapsed_time) + " s")

# reacts to the buttons on the right sode of the screen
func _on_Actions_button_selected( button_idx ):
	if button_idx == 0: # Go back to home screen
		get_tree().get_root().get_node("/root/global").setScene("res://LevelSelection.tscn")
	elif button_idx == 1: # restart level
		get_tree().get_root().get_node("/root/global").setScene("res://Level.tscn")
	elif button_idx == 2: # undo last move
		undo_move()
	elif button_idx == 3: # redo last move
		redo_move()
	# for some reason, if I don't remove the focus from the button array, subsequent arrow key presses
	# are triggering new events here... :-(
	get_node("Actions").set_focus_mode(Control.FOCUS_NONE)

# This function is called when the user presses one of the two available buttons when he finishes a level
func _on_CongratsButtons_button_selected( button_idx ):
	if button_idx == 0: # Go back to home screen
		get_tree().get_root().get_node("/root/global").setScene("res://LevelSelection.tscn")
	elif button_idx == 1: # go to next level
		var level = Globals.get("currentLevel") + 1
		# check if we reached the last level
		if level == get_tree().get_root().get_node("/root/global").levels.size():
			#in this case go back to level selection screen
			get_tree().get_root().get_node("/root/global").setScene("res://LevelSelection.tscn")
		else:
			# go to next level 
			Globals.set("currentLevel", level)
			get_tree().get_root().get_node("/root/global").setScene("res://Level.tscn")
