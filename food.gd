extends Node2D

var food_position: Vector2i
var food_counter: int
@onready var food_rects_visuals = $"/root/main/Game/FoodVisuals"

# var to save which food tile alternative was used for food sprite. changes after eating food, fixed until then
var food_tile_alt_choice: int = 0

func initialise_food(starting_food_position: Vector2i = Vector2i(14,10)):
	food_position = starting_food_position
	food_counter = 0
	#draw_food_rects(food_position)

func spawn_food():
	var attempted_food_position = Vector2i(randi_range(0,Global.grid_size-1), randi_range(0,Global.grid_size-1))
	while attempted_food_position in $"/root/main/Game/Snake".snake_body:
		attempted_food_position = Vector2i(randi_range(0,Global.grid_size-1), randi_range(0,Global.grid_size-1))
	food_position = attempted_food_position
	print("Current food position: " + str(food_position))
	#draw_food_rects(food_position)

func draw_food_rects(food_pos):
	print("Current ColorRects: " + str(food_rects_visuals))
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
