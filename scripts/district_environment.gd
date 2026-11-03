extends Node3D
## Distinct district architecture. Visual-only; never creates physics objects.
const Art = preload("res://scripts/geometry.gd")
const Materials = preload("res://scripts/environment_materials.gd")
const NAMES := ["LandscapedCourtyard","DowntownBlock","RooftopSkyline","PrecisionFacility","LogisticsDepot"]
var district := 0
var extent := 15.0

static func build(parent: Node3D, definition: Dictionary) -> Node3D:
	var scene := load("res://scripts/district_environment.gd").new() as Node3D
	parent.add_child(scene)
	scene.district = int(definition.district)
	scene.extent = 15.0 if definition.get("legacy_layout",false) else float(definition.arena)*0.5
	scene.name = NAMES[scene.district]
	scene.set_meta("visual_only",true)
	scene._build(definition)
	return scene

func _box(at: Vector3, dimensions: Vector3, kind: String, tint: Color = Color.WHITE) -> MeshInstance3D:
	var mesh := Art.box(self,at,dimensions,Color.WHITE)
	mesh.material_override = Materials.surface(kind,tint)
	if minf(dimensions.x,minf(dimensions.y,dimensions.z)) < 0.08:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh

func _paint(at: Vector3, dimensions: Vector2, color: Color) -> MeshInstance3D:
	var mesh := Art.box(self,Vector3(at.x,0.023,at.z),Vector3(dimensions.x,0.003,dimensions.y),color)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh

func _sign(text: String, at: Vector3, color: Color = Color("e8e6d5"), font_size: int = 50) -> void:
	var sign := Label3D.new()
	sign.text = text
	sign.font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	sign.font_size = font_size
	sign.pixel_size = 0.01
	sign.outline_size = 0
	sign.position = at
	sign.modulate = color
	add_child(sign)

func _build(definition: Dictionary) -> void:
	if district == 2:
		_box(Vector3(0,-28,0),Vector3(600,0.3,600),"asphalt",Color("aab1b8"))
		_rooftop()
	else:
		_box(Vector3(0,-0.55,0),Vector3(extent*2+100,0.3,extent*2+100),"concrete",Color("999e94"))
		_street_ring()
		match district:
			0: _courtyard()
			1: _downtown()
			3: _facility()
			4: _depot()
	_surface_details(definition)

func _street_ring() -> void:
	for side in [-1.0,1.0]:
		_box(Vector3(side*(extent+5),-0.3,0),Vector3(8,0.12,extent*2+20),"asphalt")
		_box(Vector3(0,-0.3,side*(extent+5)),Vector3(extent*2+20,0.12,8),"asphalt")
		_box(Vector3(side*(extent+1.0),0.02,0),Vector3(1.6,0.12,extent*2),"concrete")
		for z in range(-int(extent)-5,int(extent)+6,6):
			var stripe := _box(Vector3(side*(extent+5),-0.228,z),Vector3(0.10,0.004,2.8),"paint")
			stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for x in range(-int(extent)-5,int(extent)+6,6):
			_box(Vector3(x,-0.228,side*(extent+5)),Vector3(2.8,0.004,0.10),"paint")

func _building(at: Vector3, dimensions: Vector3, style: int, tint: Color, yaw: float = 0) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = at
	root.rotation.y = yaw
	var w := dimensions.x
	var h := dimensions.y
	var d := dimensions.z
	var body := Art.box(root,Vector3(0,h*0.5,0),dimensions,Color.WHITE)
	body.material_override = Materials.surface("brick" if style == 0 else ("metal" if style >= 3 else "plaster"),tint)
	var cap := Art.box(root,Vector3(0,h+0.1,0),Vector3(w+0.35,0.22,d+0.35),Color("596363"))
	cap.material_override = Materials.surface("concrete")
	var floors := clampi(int(h/2.8),1,12)
	# Skyline buildings need readable side and rear elevations as the chase camera turns.
	if style in [1,2]:
		for floor_index in range(floors):
			var y := 1.7+floor_index*2.8
			if y+0.8 > h: continue
			for side in [-1.0,1.0]:
				var glazing := Art.box(root,Vector3(side*(w*0.5+0.025),y,0),Vector3(0.05,1.3,d-1.0),Color.WHITE)
				glazing.material_override = Materials.surface("glass")
				glazing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				for divider in range(1,5):
					Art.box(root,Vector3(side*(w*0.5+0.06),y,-d*0.5+divider*d/5.0),Vector3(0.08,1.34,0.12),tint)
			var rear := Art.box(root,Vector3(0,y,-d*0.5-0.025),Vector3(w-1.0,1.3,0.05),Color.WHITE)
			rear.material_override = Materials.surface("glass")
			rear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for divider in range(1,5):
				Art.box(root,Vector3(-w*0.5+divider*w/5.0,y,-d*0.5-0.06),Vector3(0.12,1.34,0.08),tint)
	for floor_index in range(floors):
		if style >= 3 and floor_index == 0: continue
		var y := 1.7+floor_index*2.8
		if y+0.8 > h: continue
		var columns := clampi(int(w/2.6),2,5)
		for column in range(columns):
			var x := -w*0.5+(column+0.5)*w/columns
			var frame := Art.box(root,Vector3(x,y,d*0.5+0.035),Vector3(w/columns-0.40,1.55,0.12),Color("697778"))
			frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var window := Art.box(root,Vector3(x,y,d*0.5+0.106),Vector3(w/columns-0.58,1.32,0.025),Color.WHITE)
			window.material_override = Materials.surface("glass",Color("e4be83") if district==4 and (column+floor_index)%3==0 else Color.WHITE)
			window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			Art.box(root,Vector3(x,y,d*0.5+0.13),Vector3(0.045,1.34,0.035),Color("778482"))
			Art.box(root,Vector3(x,y-0.83,d*0.5+0.14),Vector3(w/columns-0.30,0.12,0.3),Color("b0b3aa"))
	if style >= 3:
		var bays := clampi(int(w/7.0),2,12)
		for bay_index in range(bays):
			var bay_x := -w*0.5+(bay_index+0.5)*w/bays
			Art.box(root,Vector3(bay_x,1.65,d*0.5+0.10),Vector3(3.8,3.3,0.16),Color("253335"))
			var door := Art.box(root,Vector3(bay_x,1.55,d*0.5+0.2),Vector3(3.2,3.0,0.06),Color.WHITE)
			door.material_override = Materials.surface("metal",Color("bfc7c3"))
			for slat in range(9):
				var seam := Art.box(root,Vector3(bay_x,0.3+slat*0.32,d*0.5+0.245),Vector3(3.12,0.025,0.012),Color("657475"))
				seam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			Art.box(root,Vector3(bay_x,3.4,d*0.5+0.55),Vector3(4,0.12,1.1),Color("526365"))
			for dx in [-1.75,1.75]:
				Art.box(root,Vector3(bay_x+dx,0.7,d*0.5+0.35),Vector3(0.14,1.4,0.14),Color("d6ad54"))
		for rib in range(clampi(int(w/3),2,32)):
			Art.box(root,Vector3(-w*0.5+rib*3,h*0.5,d*0.5+0.02),Vector3(0.045,h,0.045),Color("8e9c98"))
	# Low public buildings have a service entrance and canopy.
	elif h <= 8:
		Art.box(root,Vector3(0,1.3,d*0.5+0.16),Vector3(2.2,2.6,0.18),Color("293b3e"))
		Art.box(root,Vector3(0,2.8,d*0.5+0.7),Vector3(3.6,0.18,1.6),Color("596a66"))
	return root

func _courtyard() -> void:
	set_meta("features",["brick_workshops","garden_verges","paved_walks"])
	for side in [-1.0,1.0]:
		_building(Vector3(side*(extent+14),0,0),Vector3(15,5.4,8),0,Color("ded6bb"),-side*PI*0.5)
		for z in [-extent*0.65,0.0,extent*0.65]:
			_garden(Vector3(side*(extent+1.9),0,z),3.2)
			_lamp(Vector3(side*(extent+2),0,z+3.5),false)
	for x in [-extent*0.6,extent*0.6]:
		_building(Vector3(x,0,-extent-12),Vector3(12,4.2,7),0,Color("e1c7a0"))
	for x in [-4.5,4.5]:
		_box(Vector3(x,1.9,-extent-8),Vector3(0.20,3.8,0.20),"metal")
	_box(Vector3(0,3.1,-extent-8.1),Vector3(10,0.9,0.18),"metal")
	_sign("PARKSHIFT  /  DRIVING SCHOOL",Vector3(0,3.1,-extent-8),Color("e7dcc0"))

func _downtown() -> void:
	set_meta("features",["office_facades","shop_fronts","street_furniture"])
	for side in [-1.0,1.0]:
		for i in range(3):
			var z := (i-1)*minf(extent*0.8,24.0)
			_building(Vector3(side*(extent+17),0,z),Vector3(12,10+i*4,10),1,Color("b8c1bf") if i%2 else Color("d5c9b1"),-side*PI*0.5)
			_lamp(Vector3(side*(extent+1.8),0,z),false)
		_box(Vector3(side*(extent+2),0.6,extent*0.4),Vector3(0.7,1.2,0.5),"metal")
	for x in [-extent*0.55,extent*0.55]:
		_building(Vector3(x,0,-extent-13),Vector3(14,18,9),1,Color("bdc4c4"))
		_box(Vector3(x,3.3,-extent-8.3),Vector3(10,0.7,0.1),"metal",Color("738d8d"))
	_box(Vector3(0,1.7,-extent-1.1),Vector3(0.14,3.4,0.14),"metal")
	_box(Vector3(0,3.2,-extent-1.1),Vector3(6.5,1.0,0.16),"metal")
	_sign("CITY PARKING",Vector3(0,3.2,-extent-1.0),Color("d4e7e8"))

func _rooftop() -> void:
	set_meta("features",["lower_city_skyline","roof_plant","solar_panels","parapet_rails"])
	for side in [-1.0,1.0]:
		_box(Vector3(side*(extent+0.5),0.7,0),Vector3(0.45,1.4,extent*2+1),"concrete",Color("d1d6ce"))
		_box(Vector3(side*(extent+0.5),1.45,0),Vector3(0.55,0.12,extent*2+1),"metal")
		for i in range(4):
			var z := (i-1.5)*minf(extent*0.65,28.0)
			_building(Vector3(side*(extent+16+i%2*10),-28,z),Vector3(12,18+i*6,12),2,Color("b7c6cb"),-side*PI*0.5)
		for z in [-extent*0.6,extent*0.6]:
			_hvac(Vector3(side*(extent+3.5),0,z))
		for i in range(3):
			var panel := _box(Vector3(side*(extent+3),0.7,(i-1)*3.2),Vector3(2.4,0.08,2.6),"glass",Color("829cac"))
			panel.rotation.z = side*0.22
			for line in range(5):
				_box(Vector3(side*(extent+3),0.74,(i-1)*3.2-1.1+line*0.55),Vector3(2.35,0.014,0.025),"metal")
	_box(Vector3(0,1.2,-extent-3),Vector3(8,2.4,3),"concrete")
	_sign("ROOF  /  LEVEL 06",Vector3(0,1.3,-extent-1.46))

func _facility() -> void:
	set_meta("features",["test_hangar","control_room","safety_markings"])
	for side in [-1.0,1.0]:
		_building(Vector3(side*(extent+10),0,0),Vector3(extent*1.4,6.2,6),3,Color("c9cec6"),-side*PI*0.5)
		for z in [-extent*0.65,0.0,extent*0.65]:
			_box(Vector3(side*(extent+1.8),2.8,z),Vector3(0.24,5.6,0.3),"metal",Color("b3b4a7"))
			_box(Vector3(side*(extent+1.8),0.7,z),Vector3(0.28,1.4,0.34),"paint",Color("d1a84f"))
			_lamp(Vector3(side*(extent+2),0,z+2),false)
	_building(Vector3(0,0,-extent-8),Vector3(14,8,7),3,Color("b3bcae"))
	for x in [-6.0,6.0]:
		_hvac(Vector3(x,0,-extent-3))
	_sign("PRECISION  /  VEHICLE TESTING",Vector3(0,4,-extent-4.35),Color("e4dfb5"))

func _depot() -> void:
	set_meta("features",["loading_bays","warehouse_sheds","container_stacks","dusk_fixtures"])
	for side in [-1.0,1.0]:
		_building(Vector3(side*(extent+11),0,0),Vector3(extent*1.65,7.2,8),4,Color("aab4b4"),-side*PI*0.5)
		for i in range(3):
			var z := (i-1)*minf(18,extent*0.6)
			_lamp(Vector3(side*(extent+2),0,z),true)
			_box(Vector3(side*(extent+3.0),1.2,z),Vector3(2.2,2.4,5.8),"metal",Color("9e6552") if i%2 else Color("6d8e92"))
			for rib in range(12):
				_box(Vector3(side*(extent+1.87),1.2,z-2.6+rib*0.48),Vector3(0.04,2.15,0.07),"metal",Color("a6b1af"))
			_box(Vector3(side*(extent+6),0.6,z),Vector3(2.5,1.2,5.8),"concrete")
			_box(Vector3(side*(extent+4.7),0.75,z-2),Vector3(0.2,0.5,0.3),"metal")
	_building(Vector3(0,0,-extent-10),Vector3(extent*1.5,7,8),4,Color("adb4b3"))
	_sign("MASTER DEPOT  /  FREIGHT OPERATIONS",Vector3(0,4.6,-extent-5.9),Color("f1c788"))

func _garden(at: Vector3, width: float) -> void:
	_box(at+Vector3(0,0.16,0),Vector3(1.2,0.32,width+0.3),"concrete")
	_box(at+Vector3(0,0.34,0),Vector3(0.95,0.04,width),"grass")
	for i in range(3):
		var shrub := Art.cylinder(self,at+Vector3(0,0.62,(i-1)*0.9),0.5,0.55,Color("536b42"),9)
		shrub.mesh.top_radius = 0.36

func _lamp(at: Vector3, warm: bool) -> void:
	_box(at+Vector3(0,2.5,0),Vector3(0.10,5,0.10),"metal")
	_box(at+Vector3(0.5,4.9,0),Vector3(1.0,0.10,0.20),"metal")
	var lamp := _box(at+Vector3(0.7,4.82,0),Vector3(0.55,0.035,0.22),"paint")
	lamp.material_override = Art._lamp(Color("ffd2a0") if warm else Color("e5efee"))
	# Emissive mesh only; no extra mobile shadow/light passes.

func _hvac(at: Vector3) -> void:
	_box(at+Vector3(0,0.75,0),Vector3(2.6,1.5,1.9),"metal",Color("c8ccca"))
	for x in [-0.65,0.65]:
		Art.cylinder(self,at+Vector3(x,1.52,0),0.48,0.05,Color("233139"),20)
		for spoke in range(5):
			var angle := spoke*TAU/5
			var blade := _box(at+Vector3(x+cos(angle)*0.20,1.56,sin(angle)*0.20),Vector3(0.45,0.02,0.10),"metal")
			blade.rotation.y = -angle
	for row in range(7):
		_box(at+Vector3(0,0.25+row*0.16,0.965),Vector3(2.3,0.035,0.025),"metal",Color("b4bcb9"))

func _surface_details(definition: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7342 + int(definition.id)*47
	# Low-contrast wear is flush art, not collision or route guidance.
	for i in range(14):
		var at := Vector3(rng.randf_range(-extent+2,extent-2),0,rng.randf_range(-extent+2,extent-2))
		if at.distance_to(definition.bay) < 5.0 or at.distance_to(definition.start) < 4.0: continue
		var crack := _paint(at,Vector2(0.025,rng.randf_range(0.4,1.7)),Color("424741") if district==2 else Color("292d2b"))
		crack.rotation.y = rng.randf_range(-PI,PI)
		var branch := _paint(at+Vector3(0.16,0,0.1),Vector2(0.018,0.5),Color("3e433c"))
		branch.rotation.y = crack.rotation.y+0.65
	for side in [-1.0,1.0]:
		for z in [-extent*0.65,0.0,extent*0.65]:
			var at := Vector3(side*(extent-0.6),0,z)
			_paint(at,Vector2(0.4,1.6),Color("282f2f"))
			for slot in range(8):
				_paint(at+Vector3(0,0,-0.65+slot*0.18),Vector2(0.32,0.035),Color("738080"))
