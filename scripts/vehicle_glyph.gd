extends Control
## Small vector silhouettes keep the entire garage list light on mobile.
var paint := Color.WHITE
var length_ratio := 1.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(64, 48)
func _draw() -> void:
	var x := size.x * 0.5
	var y := size.y * 0.5
	var body := Rect2(Vector2(x - 27, y - 9), Vector2(54, 18))
	draw_style_box(_shape(paint), body)
	draw_colored_polygon(PackedVector2Array([Vector2(x-17,y-8),Vector2(x-10,y-18),Vector2(x+11*length_ratio,y-18),Vector2(x+21,y-8)]), paint)
	draw_colored_polygon(PackedVector2Array([Vector2(x-13,y-9),Vector2(x-8,y-15),Vector2(x+1,y-15),Vector2(x+1,y-9)]), Color("18221f"))
	draw_colored_polygon(PackedVector2Array([Vector2(x+4,y-9),Vector2(x+4,y-15),Vector2(x+10,y-15),Vector2(x+16,y-9)]), Color("18221f"))
	for wheel_x in [-16,17]:
		draw_circle(Vector2(x+wheel_x,y+9),6,Color("0d1210"),true,-1,true)
		draw_circle(Vector2(x+wheel_x,y+9),3,Color("a5aea0"),true,-1,true)
	draw_line(Vector2(x+23,y-4),Vector2(x+27,y-4),Color("f5f2d4"),3,true)
func _shape(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style
