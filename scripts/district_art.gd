extends Control
## District identity artwork: original vector city plans with no texture memory.
var district := 0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 104
	resized.connect(queue_redraw)
func _draw() -> void:
	var tones := [Color("3d4b3d"),Color("444c4a"),Color("344c50"),Color("4b473a"),Color("433f47")]
	draw_rect(Rect2(Vector2.ZERO,size),tones[district])
	var start := size.x * 0.48
	var spacing := 52.0
	for i in range(14):
		var at := Vector2(start + i * spacing - 80, -20 + (i % 3) * 22)
		var building := Rect2(at,Vector2(28 + (district % 2)*12, 128)).intersection(Rect2(Vector2.ZERO, size))
		if building.has_area():
			draw_rect(building, tones[district].lightened(0.10))
	var path := PackedVector2Array()
	for i in range(8):
		path.append(Vector2(start + i*68, size.y*0.5 + sin(i*1.1+district)*26))
	draw_polyline(path,Color("162019"),27,true)
	draw_polyline(path,Color("d4ec78"),2,true)
	var bay_at := Vector2(size.x - 80, 30)
	draw_rect(Rect2(bay_at,Vector2(24,46)),Color("d4ec78"),false,2)
	draw_line(bay_at+Vector2(5,23),bay_at+Vector2(19,23),Color("d4ec78"),2,true)
