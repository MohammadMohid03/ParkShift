extends RefCounted
## A restrained showroom with a clear car silhouette; no extra realtime lights.
const Art = preload("res://scripts/geometry.gd")
static func build(stage: Node3D) -> void:
	Art.box(stage, Vector3(0, -0.28, 0), Vector3(100, 0.4, 100), Color("303831"))
	Art.box(stage, Vector3(3.8, 2.6, -5.6), Vector3(24, 5.5, 0.3), Color("242c26"))
	for x in [-4.0, 0.0, 4.0, 8.0, 12.0]:
		Art.box(stage, Vector3(x, 2.4, -5.39), Vector3(0.035, 4.8, 0.02), Color("444d41"))
	for z in [-6.0, 0.0, 6.0, 12.0]:
		Art.box(stage, Vector3(3, -0.072, z), Vector3(26, 0.005, 0.018), Color("50594c"))
	for x in [-3.0, 3.0, 9.0]:
		Art.box(stage, Vector3(x, -0.072, 2), Vector3(0.018, 0.005, 25), Color("50594c"))
	Art.cylinder(stage, Vector3(3.8, -0.055, 0), 3.65, 0.04, Color("1a211b"), 64)
	Art.cylinder(stage, Vector3(3.8, -0.028, 0), 3.58, 0.015, Color("343e32"), 64)
	for x in [-0.1, 7.7]:
		Art.box(stage, Vector3(x, 0.005, 0), Vector3(0.045, 0.012, 8), Color("c2d786"))
	for x in [0.0, 4.0, 8.0]:
		var lamp := Art.box(stage, Vector3(x, 4.3, -5.18), Vector3(2.8, 0.07, 0.04), Color("faf2dc"))
		lamp.material_override = Art._lamp(Color("faf2dc"))
	var sign := Label3D.new()
	sign.text = "PARKSHIFT"
	sign.font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	sign.font_size = 110
	sign.pixel_size = 0.009
	sign.position = Vector3(4.0, 2.5, -5.35)
	sign.modulate = Color("84947c")
	sign.outline_size = 0
	stage.add_child(sign)
