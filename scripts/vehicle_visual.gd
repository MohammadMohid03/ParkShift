extends RefCounted
## Kiln CC0 models, adapted from +X forward to Godot -Z forward.
const Profiles = preload("res://scripts/vehicle_profiles.gd")
static var scenes: Dictionary = {}

static func build(parent: Node3D, id: String, paint: Color) -> Node3D:
	var profile := Profiles.profile(id)
	if profile.has("path"):
		return preload("res://scripts/imported_car_visual.gd").build(parent, profile)
	var path: String = "res://assets/vehicles/%s.glb" % profile.asset
	if not scenes.has(path):
		scenes[path] = load(path)
	var root := Node3D.new()
	root.name = "VehicleVisual"
	root.set_meta("asset", profile.asset)
	parent.add_child(root)
	var body: Node3D = scenes[path].instantiate()
	root.add_child(body)
	body.rotation.y = PI / 2.0
	body.position.z = profile.center_z
	# Godot does not use MSFT_lod: explicitly draw one tier, never stacked tiers.
	for tier in body.find_children("LOD*", "Node3D", true, false):
		tier.visible = tier.name == "LOD0"
	var materials := {}
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source: StandardMaterial3D = mesh.get_active_material(surface)
			if source == null:
				continue
			var key := source.resource_name
			if not materials.has(key):
				var mat := StandardMaterial3D.new()
				mat.resource_name = key
				mat.albedo_color = source.albedo_color
				mat.metallic = source.metallic
				mat.roughness = source.roughness
				mat.cull_mode = source.cull_mode
				if key == "Paint":
					mat.albedo_color = paint
					mat.metallic = 0.65
					mat.roughness = 0.25
					mat.clearcoat_enabled = true
					mat.clearcoat = 0.6
					mat.clearcoat_roughness = 0.2
				if key in ["BrakeLight", "Taillight", "Headlight"]:
					mat.emission_enabled = true
					mat.emission = mat.albedo_color
					mat.emission_energy_multiplier = 0.3
				materials[key] = mat
			if mesh.mesh.get_surface_count() == 1:
				mesh.material_override = materials[key]
			else:
				mesh.set_surface_override_material(surface, materials[key])
	for wheel in body.find_children("Wheel_*", "Node3D", true, false):
		wheel.set_meta("front", str(wheel.name).begins_with("Wheel_F"))
		var roll := Node3D.new()
		roll.name = "Roll"
		var children := wheel.get_children()
		wheel.add_child(roll)
		for child in children:
			child.owner = null
			child.reparent(roll, false)
	root.set_meta("brake_material", materials.get("BrakeLight"))
	return root
