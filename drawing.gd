extends Node2D

var current_line: Line2D
var starting_polygon: Polygon2D
var wire_remaining = 3000

var geometry_mode_pos = 0
var geometry_modes: Array[Callable] = [Geometry2D.intersect_polygons, Geometry2D.merge_polygons, 
			Geometry2D.exclude_polygons, Geometry2D.clip_polygons]

func _ready() -> void:
	starting_polygon = Polygon2D.new()
	self.add_child(starting_polygon)
	starting_polygon.set_polygon(PackedVector2Array([
		Vector2(400, 200), Vector2(250, 100), Vector2(50, 450)
	]))
	starting_polygon.color = Color.CORNFLOWER_BLUE
	
	current_line = Line2D.new()
	self.add_child(current_line)
	current_line.default_color = Color.BLACK
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND


func _process(delta: float) -> void:
	place_point()
	$CanvasLayer/wire_label.text = "Wire Remaining %d" % wire_remaining
	
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func place_point():
	var mouse_pos = get_viewport().get_mouse_position()
	var image = get_viewport().get_texture().get_image()
	if not (
			0 <= mouse_pos.x and mouse_pos.x < image.get_width() and\
			0 <= mouse_pos.y and mouse_pos.y < image.get_height()
			):
		return
	if Input.is_action_just_pressed("change_mode"):
		geometry_mode_pos = (geometry_mode_pos + 1) % len(geometry_modes)
		print(geometry_modes[geometry_mode_pos])
		

	if Input.is_action_just_pressed("place_point"):
		print('drew')
		var dist_to_last_point = 0
		if current_line.get_point_count() > 1:
			dist_to_last_point = current_line.points[-1].distance_to(mouse_pos)
		print(dist_to_last_point)
		if dist_to_last_point < wire_remaining:
			wire_remaining -= dist_to_last_point 
			current_line.add_point(mouse_pos)
			complete_shape()
			adjust_for_first_point()
		

func adjust_for_first_point():
	var extra = Vector2(3, 3)
	if current_line.get_point_count() == 1:
		current_line.add_point(current_line.get_point_position(0) + extra)
	elif current_line.get_point_position(0) + extra == current_line.get_point_position(1) :
		current_line.remove_point(1)


func complete_shape():
	var dist = current_line.points[0].distance_to(current_line.points[-1])
	prints("dist", dist)
	if len(current_line.points) > 1 and dist < 20:
		print("shape complete!")
		var intersection_calc = geometry_modes[geometry_mode_pos].call(
				starting_polygon.polygon, current_line.points
		)
		prints("intersection calc", intersection_calc)
		for overlapping_polygon in intersection_calc:
			var intersection_polygon = Polygon2D.new()
			prints("overlapping_polygon", overlapping_polygon)
			self.add_child(intersection_polygon)
			intersection_polygon.color = Color.GREEN
			intersection_polygon.set_polygon(overlapping_polygon)
			print(intersection_polygon.polygon)
		self.remove_child(starting_polygon)
