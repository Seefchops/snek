extends Node

@onready var score_label = $"/root/main/UI/Score"
@onready var game_timer = $"/root/main/Game/GameTimer"
@onready var start_game_button = $"/root/main/UI/StartGame"
@onready var game_message = $"/root/main/UI/Message"
@onready var message_timer = $"/root/main/UI/MessageTimer"

@onready var settings_button = $"/root/main/UI/Settings"
@onready var difficulty_label = $"/root/main/UI/Settings/DifficultyLabel"
@onready var easy_button = $"/root/main/UI/Settings/EasyDifficulty"
@onready var medium_button = $"/root/main/UI/Settings/MediumDifficulty"
@onready var hard_button = $"/root/main/UI/Settings/HardDifficulty"
@onready var map_select_label = $"/root/main/UI/Settings/MapSelectLabel"
@onready var basic_map_button = $"/root/main/UI/Settings/BasicMapButton"
@onready var desert_map_button = $"/root/main/UI/Settings/DesertMapButton"

@onready var name_entry_line = $"/root/main/UI/NameEntryLine"
@onready var name_entry_label = $"/root/main/UI/NameEntryLabel"
@onready var leaderboard_button: Button = $"/root/main/UI/LeaderboardButton"
@onready var leaderboard_header: Label = $"/root/main/UI/LeaderboardButton/LeaderboardHeader"
@onready var leaderboard_table: Label = $"/root/main/UI/LeaderboardButton/LeaderboardTable"
@onready var leaderboard_grid: GridContainer = $"/root/main/UI/LeaderboardButton/LeaderboardGrid"

@onready var snake_tile_map_layer = $"/root/main/Game/SnakeTileSetLayer"
var atlas_id = 2 # set to use 320x tileset atlas
var food_atlas_coord = Vector2i(0,1) # set to use correct food tile in atlas
var empty_tile_atlas_coord = Vector2i(0,0)
var snake_head_atlas_coord = Vector2i(1,0)
var snake_body_atlas_coord = Vector2i(2,0) 
var snake_tail_atlas_coord = Vector2i(3,0)
var snake_bend_atlas_coord = Vector2i(1,1)

@onready var color_rects_visuals = $"/root/main/Game/SnakeVisuals" # backup for playing snake by ColorRects
@onready var food_rects_visuals = $"/root/main/Game/FoodVisuals"
var graphic_mode_dict: Dictionary = {"basic":draw_snake_tiles, "desert":draw_snake_rectangles}
var graphic_mode_selected: String = ""

# dictionary that holds four keys for cardinal directions matched to alternative tile IDs for different head tiles
var head_rotation_dictionary: Dictionary = {Vector2i(1,0):0, Vector2i(-1,0):2, Vector2i(0,1):3, Vector2i(0,-1):4}

# dictionary that holds different possibilities for snake shape and returns different tiles for render
# 4 entries for clockwise turns, 4 entries for ccw turns
var body_rotation_dictionary: Dictionary = {"(0, 1), (-1, 0)":0, "(1, 0), (0, 1)":2, "(0, -1), (1, 0)":3, "(-1, 0), (0, -1)":4, "(0, -1), (-1, 0)":4, "(-1, 0), (0, 1)": 0, "(0, 1), (1, 0)": 2, "(1, 0), (0, -1)": 3}
var straight_body_dictionary: Dictionary = {"(1, 0), (-1, 0)":0, "(0, 1), (0, -1)": 1, "(-1, 0), (1, 0)":2, "(0, -1), (0, 1)": 3}

# adjusted for different difficulties. easy = 1, med = 2, hard = 3
var score_increment: int = 1

# holds all setting buttons within for easy hiding/showing
var ui_settings_buttons = []

var score: int
var game_over: bool
var difficulty_mode = "easy"
# dictionary to hold difficulty settings. arrays hold, in order: [tick timer, score per food]
var diff_modes: Dictionary = {"easy":[0.5, 1],"medium":[0.25, 2],"hard":[0.1, 3]}

var leaderboard_array: Array = []

func difficulty_check(difficulty):
	var difficulty_values = diff_modes.get(difficulty)
	game_timer.wait_time = difficulty_values[0]
	score_increment = difficulty_values[1]
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialise_ui()

func restart_game():
	game_over = false
	start_game_button.hide()
	settings_button.hide()
	leaderboard_button.hide()
	for child in color_rects_visuals.get_children():
		child.queue_free()
	for child in food_rects_visuals.get_children():
		child.queue_free()
	show_message("Game starting, get ready!")
	$Snake.initialize_snake()
	$Food.initialise_food()
	draw_board_tiles()
	reset_score()
	await message_timer.timeout
	game_message.hide()
	game_timer.start()

func reset_score():
	score = 0
	score_label.text = "Score: " + str(score)
	score_label.show()

func end_game():
	game_timer.stop()
	game_over = true
	score_label.hide()
	show_message("Game over, your score was: " + str(score))
	if score > int(leaderboard_array[-1]["score"]):
		print("Your score made it to the leaderboard!")
		name_entry_label.show()
		name_entry_line.show()
		name_entry_line.grab_focus()
	else:
		start_game_button.show()
		settings_button.show()
		leaderboard_button.show()

func show_message(text):
	game_message.text = text
	game_message.show()
	message_timer.start()

func initialise_ui():
	score_label.hide()
	start_game_button.show()
	settings_button.show()
	start_game_button.grab_focus()
	ui_settings_buttons.append(difficulty_label)
	ui_settings_buttons.append(easy_button)
	ui_settings_buttons.append(medium_button)
	ui_settings_buttons.append(hard_button)
	ui_settings_buttons.append(map_select_label)
	ui_settings_buttons.append(basic_map_button)
	ui_settings_buttons.append(desert_map_button)
	for button in ui_settings_buttons:
			button.hide()
	load_leaderboard()
	leaderboard_button.show()
	show_message("Welcome to the game! Click 'Start game' or press Start on your controller to begin.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func tick() -> void:
	# update snake_direction with attempted_direction if allowed 
	var reversal = $Snake.reversal_check()
	if reversal == true:
		$Snake.snake_direction = $Snake.attempted_direction
	else: 
		pass
	
	#print("Current head position: " + str($Snake.snake_body[0]))
	
	# get next head
	var next_head_pos = $Snake.next_head_pos_calc()
	
	# check valid
	var check_valid = $Snake.check_validity(next_head_pos)
	var food_pos = $Food.food_position
	
	# if invalid, game over. if valid, insert new head and pop tail. 
	if check_valid == false:
		end_game()
		
	elif next_head_pos == food_pos:
		#print("Food eaten! Snake growing")
		$Food.food_counter += 1
		score += score_increment
		score_label.text = "Score: " + str(score)
		$Food.spawn_food()
		$Food.food_tile_alt_choice = randi() % 8
		draw_food_tile()
		$Snake.snake_body.push_front(next_head_pos)
	else: 
		# add new head to next_head_pos
		$Snake.snake_body.push_front(next_head_pos)
		# remove tail if no food eaten
		$Snake.remove_tail($Snake.snake_body)
	#$Snake.draw_snake_rectangles($Snake.snake_body)
	draw_board_tiles() # replaces all other drawing functions
	## print snake_body at end of tick
	#print($Snake.snake_body)

# replacement func for draw_snake_rectangles
# likely to be heavy usage of set_cell method of the TileMapLayer object




func draw_food_tile():
	# draws food tile at food position, uses randi to choose alternative tile randomly
	snake_tile_map_layer.set_cell($Food.food_position, atlas_id, food_atlas_coord, $Food.food_tile_alt_choice)
	# removed "randi() % 8" from end of prev line. this would have chosen a random food alternative however:
	# when the board is cleared and redrawn each tick, the food is also redrawn
	# if we want the food to remain in a single orientation until eaten, we either need to
	# store the alternative chosen for the food until eaten, or to not clear food when board is cleared.
	
	
# func to draw simple color rectangles for food visual
func draw_food_rects(food_pos):
	#print("Current ColorRects: " + str(food_rects_visuals))
	var food_rects_visuals_children = food_rects_visuals.get_children()
	for child in food_rects_visuals_children:
		child.queue_free()
	
	var food_rect = ColorRect.new()
	food_rect.size = Vector2(Global.cell_size, Global.cell_size)
	food_rect.color = "brown"
	var pixel_coord = Global.convert_grid_to_pixel(food_pos.x, food_pos.y)
	food_rect.position = pixel_coord
	print("Drawing color rectangle of position: " + str(pixel_coord))
	food_rects_visuals.add_child(food_rect)

func draw_snake_tiles():
	snake_tile_map_layer.set_cell($Snake.snake_body[0], atlas_id, snake_head_atlas_coord, head_rotation_dictionary.get($Snake.snake_direction))
	snake_tile_map_layer.set_cell($Snake.snake_body[-1], atlas_id, snake_tail_atlas_coord, head_rotation_dictionary.get(($Snake.snake_body[-2])-($Snake.snake_body[-1])))
	for i in range(1, len($Snake.snake_body)-1):
		var prev_segment = $Snake.snake_body[i-1]
		var next_segment = $Snake.snake_body[i+1]
		var segment_position = $Snake.snake_body[i]
		var prev_diff = prev_segment - segment_position
		var next_diff = next_segment - segment_position
		# print functions to help in finding difference patterns as body shape moves
		#print("Tile closer to head relative to body: " + str(prev_diff))
		#print("Tile closer to tail relative to body: " + str(next_diff))
		var diff_string = str(prev_diff) + ", " + str(next_diff)
		#print(diff_string)
		
		if prev_diff == -next_diff:
			# uses the 'straight body' dictionary which only contains straight segment alternatives, not turns
			snake_tile_map_layer.set_cell(segment_position, atlas_id, snake_body_atlas_coord, straight_body_dictionary.get(diff_string))
		else: 
			# lookup difference between prev and next body tiles to find which body bend alt should be used 
			snake_tile_map_layer.set_cell(segment_position, atlas_id, snake_bend_atlas_coord, body_rotation_dictionary.get(diff_string))

# draws basic tile on all tiles in game before other tiles are drawn on top 
# could potentially set up as its own tilemap layer which is always on, and always behind other layer. this could even allow separation of snake design from level design, allowing player customisation of their own snake
func draw_base_board_tiles():
	for i in range(0, Global.grid_size):
		for j in range(0, Global.grid_size):
			snake_tile_map_layer.set_cell(Vector2i(i, j), atlas_id, empty_tile_atlas_coord)

func draw_board_tiles():
	#clears board for tile redraws
	snake_tile_map_layer.clear()
	if graphic_mode_selected == "basic":
		draw_snake_rectangles($Snake.snake_body)
		draw_food_rects($Food.food_position)
	else:
		draw_base_board_tiles()
		draw_snake_tiles()
		draw_food_tile()

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
		print("Drawing color rectangle of position: " + str(pixel_coord))
		color_rects_visuals.add_child(snake_rect)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_button"):
		_on_start_game_pressed()
	elif event.is_action_pressed("ui_accept"):
		if get_viewport().gui_get_focus_owner() == settings_button:
			_on_settings_pressed()
		elif get_viewport().gui_get_focus_owner() == easy_button:
			_on_easy_difficulty_pressed()
		elif get_viewport().gui_get_focus_owner() == medium_button:
			_on_medium_difficulty_pressed()
		elif get_viewport().gui_get_focus_owner() == hard_button:
			_on_hard_difficulty_pressed()
		elif get_viewport().gui_get_focus_owner() == start_game_button:
			_on_start_game_pressed()


func _on_start_game_pressed() -> void:
	restart_game()
	start_game_button.hide()
	settings_button.hide()


func _on_settings_pressed() -> void:
	if easy_button.visible == false: 
		for button in ui_settings_buttons:
			button.show()
		settings_button.grab_focus()
	else:
		for button in ui_settings_buttons:
			button.hide()
		settings_button.grab_focus()


func _on_easy_difficulty_pressed() -> void:
	difficulty_mode = "easy"
	game_message.text = "Difficulty changed to " + difficulty_mode
	difficulty_check(difficulty_mode)
	for button in ui_settings_buttons:
		button.hide()
	settings_button.grab_focus()


func _on_medium_difficulty_pressed() -> void:
	difficulty_mode = "medium"
	game_message.text = "Difficulty changed to " + difficulty_mode
	difficulty_check(difficulty_mode)
	for button in ui_settings_buttons:
		button.hide()
	settings_button.grab_focus()


func _on_hard_difficulty_pressed() -> void:
	difficulty_mode = "hard"
	game_message.text = "Difficulty changed to " + difficulty_mode
	difficulty_check(difficulty_mode)
	for button in ui_settings_buttons:
		button.hide()
	settings_button.grab_focus()

func load_leaderboard():
	var test_path = "user://testldb.json"
	var test_file
	# FileAccess class flags: 	read mode = 1 / READ, write mode = 2 / WRITE
	# continued flags: 			read_write = 3, write_read = 7
	# for FileAccess class, method for opening a file is .open(path, flags)
	# for FileAccess class, method for writing to a file is store - store_string() for strings
	
	# store_string does not work in READ mode when testldb.json does not already exist. 
	if FileAccess.file_exists(test_path) == true:
		test_file = FileAccess.open(test_path, FileAccess.READ)
		leaderboard_array = (test_file.get_var())
		#print(leaderboard_array)
		#print("Sorting leaderboard...")
		leaderboard_array.sort_custom(sort_descending)
		#print("Leaderboard sorted!")
		#print(leaderboard_array)
		create_leaderboard_table()
	else:
		print("No leaderboard file exists. Creating...")
		test_file = FileAccess.open(test_path, FileAccess.WRITE)
		create_basic_leaderboard()
		print("Basic leaderboard created!")
		test_file.store_var(leaderboard_array)
		create_leaderboard_table()
	# if file exists, function opens it in READ mode
	
	#print(OS.get_user_data_dir()) # prints user:// directory
	#print(test_file.get_as_text()) # prints file as text
	

func sort_descending(a, b):
	if int(a["score"]) < int(b["score"]):
		return false
	return true

func create_basic_leaderboard():
	leaderboard_array.append({"name":"Spazzy McGee", "difficulty":"hard", "score":"1000"})
	leaderboard_array.append({"name":"Honda Savage", "difficulty":"hard", "score":"900"})
	leaderboard_array.append({"name":"Kit Tsune", "difficulty":"hard", "score":"800"})
	leaderboard_array.append({"name":"Anni Versaire", "difficulty":"hard", "score":"700"})
	leaderboard_array.append({"name":"Bar Tech", "difficulty":"medium", "score":"600"})
	leaderboard_array.append({"name":"Buried Spade", "difficulty":"medium", "score":"500"})
	leaderboard_array.append({"name":"Nosfer Atu", "difficulty":"medium", "score":"250"})
	leaderboard_array.append({"name":"Miji Onna", "difficulty":"easy", "score":"100"})
	leaderboard_array.append({"name":"Down Load", "difficulty":"easy", "score":"50"})
	leaderboard_array.append({"name":"Pasta Fasta", "difficulty":"easy", "score":"10"})

func save_to_ldb_array(player_name):
	print("Saving name...")
	leaderboard_array.pop_back()
	#print(str({"name" = name, "difficulty" = difficulty_mode, "score" = score}))
	leaderboard_array.append({"name":player_name, "difficulty":difficulty_mode, "score":str(score)})
	leaderboard_array.sort_custom(sort_descending)
	print("New leaderboard is as follows: \n" + str(leaderboard_array))
	save_leaderboard()
	create_leaderboard_table()
	name_entry_label.hide()
	name_entry_line.hide()
	start_game_button.show()
	settings_button.show()
	leaderboard_button.show()

func save_leaderboard():
	var test_path = "user://testldb.json"
	var test_file = FileAccess.open(test_path, FileAccess.WRITE)
	test_file.store_var(leaderboard_array)
	
	#test_file.store_string("Hello, world!") # writes test string to file 

func create_leaderboard_table():
	for child in leaderboard_grid.get_children():
		child.queue_free()
	
	
	var column_header_name: Label = Label.new()
	column_header_name.text = "Player name"
	column_header_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column_header_name.add_theme_constant_override("outline_size", 5)
	leaderboard_grid.add_child(column_header_name)
	
	var column_header_diff: Label = Label.new()
	column_header_diff.text = "Difficulty"
	column_header_diff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column_header_diff.add_theme_constant_override("outline_size", 5)
	leaderboard_grid.add_child(column_header_diff)
	
	var column_header_score: Label = Label.new()
	column_header_score.text = "Score"
	column_header_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column_header_score.add_theme_constant_override("outline_size", 5)
	leaderboard_grid.add_child(column_header_score)
	
	for entry in leaderboard_array:
		var player_name = entry["name"]
		var player_diff = entry["difficulty"]
		var player_score = entry["score"]
		
		var player_name_label = Label.new()
		player_name_label.text = player_name
		player_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		leaderboard_grid.add_child(player_name_label)
		
		var player_diff_label = Label.new()
		player_diff_label.text = player_diff
		player_diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		leaderboard_grid.add_child(player_diff_label)
		
		var player_score_label = Label.new()
		player_score_label.text = player_score
		player_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		leaderboard_grid.add_child(player_score_label)
		
	

func _on_leaderboard_button_pressed() -> void:
	## leaderboard labels returning null instances
	## resolved through using absolute path for @onready calls (must begin with \ for absolute, otherwise relative)
	#print("leaderboard button type: \n")
	#print(leaderboard_button)
	#print("leaderboard header type: \n")
	#print(leaderboard_header)
	#print("leaderboard table type: \n")
	#print(leaderboard_table)
	#print(typeof(leaderboard_array))
	#print("settings button type: \n")
	#print(settings_button)
	#print("easy mode type: \n")
	#print(easy_button)
	#print("hard mode type: \n")
	#print(hard_button)
	
	
	if leaderboard_header.visible == false: 
		game_message.hide()
		leaderboard_header.show()
		leaderboard_grid.show()
		leaderboard_button.grab_focus()
	else:
		game_message.show()
		leaderboard_header.hide()
		leaderboard_grid.hide()
		leaderboard_button.grab_focus()

	# step 1: write a simple test value to a user:// file and read it back  -done
	# step 2: build the in-memory top-10 list structure and the insert/sort/trim logic -done
	# step 2.5: test with made up scores -done
		#[{"name":"One", "difficulty":"hard", "score":"1000"}, 
		#{"name":"Two", "difficulty":"hard", "score":"900"}, 
		#{"name":"Three", "difficulty":"hard", "score":"800"}, 
		#{"name":"Four", "difficulty":"hard", "score":"700"}, 
		#{"name":"Five", "difficulty":"medium", "score":"600"}, 
		#{"name":"Six", "difficulty":"medium", "score":"500"}, 
		#{"name":"Seven", "difficulty":"medium", "score":"400"}, 
		#{"name":"Eight", "difficulty":"easy", "score":"300"}, 
		#{"name":"Nine", "difficulty":"easy", "score":"200"}, 
		#{"name":"Ten", "difficulty":"easy", "score":"100"}]
	# step 3: wire up 'save on game over' and 'load on startup' -done
	# step 4: build UI elements to display the leaderboard
		# print(leaderboard_array[0]["name"] + "\t" + leaderboard_array[0]["difficulty"] + "\t" + leaderboard_array[0]["score"])
		# this prints "Spazzy McGee 	hard	1000"
		# can use this format to display all scores in leaderboard under a single label
	


func _on_basic_map_button_pressed() -> void:
	graphic_mode_selected = "basic"
	game_message.text = "Map changed to " + graphic_mode_selected
	for button in ui_settings_buttons:
		button.hide()
	settings_button.grab_focus()

func _on_desert_map_button_pressed() -> void:
	graphic_mode_selected = "desert"
	game_message.text = "Map changed to " + graphic_mode_selected
	for button in ui_settings_buttons:
		button.hide()
	settings_button.grab_focus()
