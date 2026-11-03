extends RefCounted
## Prepared meshes are Y-up, -Z forward, ground-centred, with independent wheels.
static func build(parent: Node3D, profile: Dictionary) -> Node3D:
	var scene := preload("res://scripts/car_resource_cache.gd").scene_for(profile.path)
	var root := Node3D.new()
	root.name = "VehicleVisual"
	root.set_meta("asset", profile.asset)
	parent.add_child(root)
	if scene == null:
		push_error("Unable to load vehicle: " + str(profile.path))
		return root
	var body: Node3D = scene.instantiate()
	root.add_child(body)
	var brake_materials: Array[StandardMaterial3D] = []
	var copies := {}
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		mesh.lod_bias = 0.25
		# Preserve embedded textures, UVs, normal maps, transparency and PBR values.
		# Source materials are shared, avoiding repeated copies of large textures.
		for surface in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = mesh.get_active_material(surface)
			if material != null and material.resource_name.begins_with("ParkingBrakeLight"):
				if not copies.has(material.resource_name):
					var copy: StandardMaterial3D = material.duplicate()
					copy.emission_enabled = true
					copy.emission_energy_multiplier = 0.3
					copies[material.resource_name] = copy
					brake_materials.append(copy)
				mesh.set_surface_override_material(surface, copies[material.resource_name])
	for wheel in body.find_children("Wheel_*", "MeshInstance3D", true, false):
		var pivot := Node3D.new()
		var wheel_name: String = wheel.name
		wheel.name = "WheelMesh"
		wheel.get_parent().add_child(pivot)
		pivot.name = wheel_name
		pivot.transform = wheel.transform
		pivot.set_meta("front", wheel_name.begins_with("Wheel_F"))
		pivot.set_meta("roll_axis", Vector3.RIGHT)
		var definition := preload("res://scripts/imported_car_catalog.gd").find(profile.asset)
		pivot.set_meta("radius", float(definition.wheels[wheel_name].radius))
		var roll := Node3D.new()
		roll.name = "Roll"
		pivot.add_child(roll)
		wheel.owner = null
		wheel.reparent(roll, false)
		wheel.transform = Transform3D.IDENTITY
	root.set_meta("brake_materials", brake_materials)
	return root
