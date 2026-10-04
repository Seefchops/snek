extends Node2D


@onready var color_rects_visuals = $"/root/main/Game/SnakeVisuals"
# direction requires setting up in a manner where the player cannot 180 reverse ie (1,0) cannot directly go to (-1,0)
var snake_direction: Vector2i = Vector2i(1,0)
# separate direction variable for handling inputs
var attempted_direction: Vector2i = Vector2i(1,0)

var snake_length: int = 3
var snake_position: Vector2i = Vector2i(6,10)

# create array type object to contain grid coordinates (type: Vector2i) with the head being at index 0, tail at -1
var snake_body: Array[Vector2i] = []



# func to reset snake pos, len and dir to starting positions
func initialize_snake(starting_direction = Vector2i(1,0), starting_position = Vector2i(6,10), starting_length = 3, default_attempt_dir = Vector2i(1,0)):
	# start near to the middle, slightly to the left and moving rightwards
	snake_position = starting_position
	
	# length starts with head, one body segment and tail
	snake_length = starting_length
	
	# directions are sorted positive x is right direction, positive y is down direction, negatives are reverse
	# direction should only ever be either (1,0) or (-1,0) or (0,1) or (0,-1) 
	# assert True condition, return error message when false
	assert(starting_direction.length() <= 1, "Invalid direction")
	snake_direction = starting_direction
	attempted_direction = default_attempt_dir
	# reset snake body and remove visuals
	snake_body = []
	# simple for loop that returns x as 0, then 1, then 2 (for length of three)
	# formula for append is (pos - x*dir) where x starts at 0 so head is placed at start pos
	for x in range(0, starting_length):
		snake_body.append(starting_position - (x * starting_direction))
	
	#draw_snake_rectangles(snake_body)

# func to insert new head pos at the front of the array; occurring every movement tick
# break it down: first, calc next head pos
func next_head_pos_calc():
	var current_snake_head = snake_body[0]
	#print("Current snake head position: " + str(current_snake_head))
	var next_snake_head = current_snake_head + snake_direction
	#print("Predicted snake head position: " + str(next_snake_head))
	return next_snake_head

# func to check that next head position is valid; occurring every movement tick
func check_validity(pos):
	var position_to_check = pos
	if position_to_check.x >= Global.grid_size or position_to_check.y >= Global.grid_size:
		return false
	elif position_to_check.x < 0 or position_to_check.y < 0:
		return false
	elif position_to_check in snake_body:
		return false
	else:
		return true

# func to remove the last element of the array; occurring every movement tick UNLESS you just ate
func remove_tail(body):
	body.pop_back()

func reversal_check():
	#print("Attempted direction of movement: " + str(attempted_direction))
	#print("Current direction of movement: " + str(snake_direction))
	
	if attempted_direction == (-1*snake_direction):
		#print("Unable to turn that way, would collide with body!")
		return false
	else:
		#print("Applying new direction... " + str(attempted_direction))
		return true

# handling inputs 
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		#print("Button pressed! left")
		attempted_direction = Vector2i(-1, 0)
		#print("Attempting to change to direction: " + str(attempted_direction))
	elif event.is_action_pressed("move_right"):
		#print("Button pressed! right")
		attempted_direction = Vector2i(1, 0)
		#print("Attempting to change to direction: " + str(attempted_direction))
	elif event.is_action_pressed("move_up"):
		#print("Button pressed! up")
		attempted_direction = Vector2i(0, -1)
		#print("Attempting to change to direction: " + str(attempted_direction))
	elif event.is_action_pressed("move_down"):
		#print("Button pressed! down")
		attempted_direction = Vector2i(0, 1)
		#print("Attempting to change to direction: " + str(attempted_direction))
	

	# add the 'unless you ate' option as an integer so super powered food could increase length by 5 instead of 1
	# if added, snake can start from a single coordinate and have a starting counter to apply initial length

# may not sit within this script, but may be best spot for it in the end
		# func to check whether a given coordinate is already in the array; for setting up self-collision

		# timer restart

		# func to reset food on the field


		# func to reset score back to zero

# func to draw ColorRect nodes at coordinates in snake body
func draw_snake_rectangles(body):
	#print("Current ColorRects: " + str(color_rects_visuals))
	var color_rects_visuals_children = color_rects_visuals.get_children()
	for child in color_rects_visuals_children:
		child.queue_free()
	
	for coord in body:
		var snake_rect = ColorRect.new()
		snake_rect.size = Vector2(Global.cell_size, Global.cell_size)
		snake_rect.color = "green"
		var pixel_coord = Global.convert_grid_to_pixel(coord.x, coord.y)
		snake_rect.position = pixel_coord
		#print("Drawing color rectangle of position: " + str(pixel_coord))
		color_rects_visuals.add_child(snake_rect)
	
		# func needs overhauling and moving to game.gd. need to integrate TileMapLayers 



#func tick() -> void:
	## update snake_direction with attempted_direction if allowed 
	#var reversal = reversal_check(attempted_direction, snake_direction)
	#if reversal == true:
		#snake_direction = attempted_direction
	#else: 
		#pass
	#
	#print(str(snake_body))
	#
	## get next head
	#var next_head_pos = next_head_pos_calc()
	#
	## check valid
	#var check_valid = check_validity(next_head_pos)
	#
	## if invalid, game over. if valid, insert new head and pop tail. 
	#if check_valid == false:
		#print("Game over!")
	#else: 
		## add new head to next_head_pos
		#snake_body.push_front(next_head_pos)
		## remove tail if no food eaten
		#remove_tail(snake_body)
	#draw_snake_rectangles(snake_body)
	## print snake_body at end of tick
	#print(snake_body)
