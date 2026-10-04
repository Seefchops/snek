extends Node

var grid_size = 20
var cell_size = 32

func convert_pixel_to_grid(pixel_x, pixel_y):
	var grid_x = pixel_x / cell_size
	var grid_y = pixel_y / cell_size
	var grid_coords = Vector2i(grid_x, grid_y)
	return grid_coords

func convert_grid_to_pixel(grid_x, grid_y):
	var pixel_x = grid_x * cell_size
	var pixel_y = grid_y * cell_size
	var pixel_coords = Vector2(pixel_x, pixel_y)
	return pixel_coords

func check_pos_valid(pos):
	if pos.x >= grid_size or pos.x < 0:
		return false
	elif pos.y >= grid_size or pos.y < 0:
		return false
	
