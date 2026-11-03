extends "res://scripts/level_world.gd"
## Modular district dressing. Rooftops remain a flat, guarded deck.
const PALETTES := [Color("c7c4a8"), Color("a7b2af"), Color("c4d1ca"), Color("c7b591"), Color("818d83")]

func build(definition: Dictionary, index: int) -> void:
	var district: int = int(definition.district)
	if definition.get("legacy_layout", false):
		super.build(definition, index)
	else:
		var extent: float = float(definition.arena) * 0.5
		Art.box(self, Vector3(0, -0.18, 0), Vector3(extent * 2, 0.36, extent * 2), Color("3b4d5e"))
		Art.collider(self, Vector3(0, -0.2, 0), Vector3(extent * 2, 0.4, extent * 2), false)
		for side in [-1.0, 1.0]:
			for axis in [0, 1]:
				var at := Vector3(side * extent, 0.55, 0) if axis == 0 else Vector3(0, 0.55, side * extent)
				var size := Vector3(0.35, 1.1, extent * 2) if axis == 0 else Vector3(extent * 2, 1.1, 0.35)
				Art.box(self, at, size, PALETTES[district])
				Art.collider(self, at, size)
		for block in definition.blocks:
			var center: Vector3 = block.at + Vector3.UP * block.size.y * 0.5
			var obstacle := Art.bevel_box(self, center, block.size, PALETTES[district], 0.06)
			obstacle.material_override = preload("res://scripts/automotive_world.gd").surface("concrete")
			Art.collider(self, center, block.size)
			if block.kind == "planter":
				Art.box(self, block.at + Vector3.UP * (block.size.y + 0.02), Vector3(block.size.x - 0.16, 0.04, block.size.z - 0.16), Color("718e7a"))
			else:
				Art.box(self, center + Vector3(0, block.size.y * 0.25, -block.size.z * 0.501), Vector3(block.size.x * 0.8, 0.12, 0.015), Color("ed974d"))
		for parked in definition.parked:
			var holder := Node3D.new()
			add_child(holder)
			holder.position = parked.at
			holder.rotation.y = parked.yaw
			preload("res://scripts/vehicle_visual.gd").build(holder, "metro", Color("78919b"))
			Art.collider(holder, Vector3(0, 0.65, 0), Vector3(1.82, 1.3, 4.26))
		bay = BayScene.instantiate()
		add_child(bay)
		bay.configure(definition.bay, definition.bay_yaw, definition.bay_size, definition.reverse)
	if index == 0:
		preload("res://scripts/automotive_world.gd").finish_yard(self)
	_apply_surfaces(district, float(definition.arena) * 0.5 - 0.5)
	if not definition.get("legacy_layout", false):
		var last: Vector3 = definition.start
		for point in definition.route:
			var edge: Vector3 = point - last
			edge.y = 0
			var distance := edge.length()
			if distance > 3.5:
				for step in range(1, int(distance / 3.0) + 1):
					var at: Vector3 = last.lerp(point, float(step) / (int(distance / 3.0) + 1))
					at.y = 0.012
					var mark := Art.box(self, at, Vector3(0.08, 0.012, 0.65), Color("869597"))
					mark.rotation.y = atan2(edge.x, edge.z)
			last = point
	preload("res://scripts/district_environment.gd").build(self, definition)
	preload("res://scripts/background_scenery.gd").build(self, definition)
	# Flush district stencil beside the start, readable without adding scenery
	# collision or another real-time light to the driving corridor.
	var direction: Vector3 = definition.route[0] - definition.start
	direction.y = 0
	direction = direction.normalized()
	var right := Vector3(-direction.z, 0, direction.x)
	var stencil := Label3D.new()
	stencil.text = "%s / %02d" % [preload("res://scripts/campaign_catalog.gd").DISTRICTS[district].to_upper(), index + 1]
	stencil.position = definition.start + direction * 4 + right * 5.5
	var margin: float = float(definition.arena) * 0.5 - 3.0
	stencil.position.x = clampf(stencil.position.x, -margin, margin)
	stencil.position.z = clampf(stencil.position.z, -margin, margin)
	stencil.position.y = 0.028
	stencil.rotation = Vector3(-PI / 2, atan2(-direction.x, -direction.z), 0)
	stencil.font_size = 36
	stencil.pixel_size = 0.006
	stencil.outline_size = 0
	stencil.modulate = Color("c3ba99") if district < 3 else Color("d5a465")
	add_child(stencil)

func _build_surroundings(_index: int) -> void:
	# District-specific visual architecture is built after the shared layout.
	pass

func batch_static_meshes() -> void:
	# Static art is merged by material; collision bodies and the reactive bay stay separate.
	var groups := {}
	for instance in find_children("*", "MeshInstance3D", true, false):
		if bay.is_ancestor_of(instance) or instance.mesh == null or not instance.is_visible_in_tree():
			continue
		var mat: Material = instance.material_override
		if mat == null:
			continue
		var key: Variant = mat.get_instance_id()
		if mat is StandardMaterial3D:
			# Procedural materials have no textures; equal appearance can share one draw.
			key = str([mat.albedo_color, mat.roughness, mat.metallic, mat.clearcoat_enabled, mat.clearcoat, mat.clearcoat_roughness, mat.emission_enabled, mat.emission, mat.emission_energy_multiplier, mat.cull_mode, mat.albedo_texture, mat.normal_enabled, mat.normal_texture, mat.normal_scale, mat.uv1_triplanar, mat.uv1_world_triplanar, mat.uv1_scale])
		# Box meshes contain UV/tangent channels; bevel meshes do not. Mixing
		# their vertex formats in one SurfaceTool can drop the bevel geometry.
		key = str(key) + ":" + str(instance.cast_shadow) + ":" + instance.mesh.get_class()
		if instance.mesh is ArrayMesh:
			key += ":" + str(instance.mesh.surface_get_format(0))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(instance)
	for group in groups.values():
		if group.size() < 2:
			continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for instance in group:
			surface.append_from(instance.mesh, 0, global_transform.affine_inverse() * instance.global_transform)
		var merged := MeshInstance3D.new()
		merged.mesh = surface.commit()
		merged.material_override = group[0].material_override
		merged.cast_shadow = group[0].cast_shadow
		add_child(merged)
		for instance in group:
			instance.get_parent().remove_child(instance)
			instance.queue_free()

func _apply_surfaces(district: int, extent: float) -> void:
	var floor_mat := preload("res://scripts/surface_library.gd").floor_material(district)
	for mesh in get_children():
		if mesh is MeshInstance3D and mesh.mesh is BoxMesh:
			var size: Vector3 = mesh.mesh.size
			if size.x > 20 and size.z > 20 and mesh.position.y > -0.2:
				mesh.material_override = floor_mat
	# Expansion joints and drainage remain flush with the collision floor.
	for z in range(-int(extent) + 3, int(extent) - 2, 5):
		Art.box(self, Vector3(0, 0.008, z), Vector3(extent * 2, 0.003, 0.018), Color("31383e"))
	for side in [-1.0, 1.0]:
		Art.box(self, Vector3(side * extent, 0.01, 0), Vector3(0.18, 0.012, extent * 2), Color("242c32"))
		for z in range(-int(extent) + 2, int(extent) - 1, 2):
			Art.box(self, Vector3(side * extent, 0.018, z), Vector3(0.19, 0.008, 0.04), Color("859096"))
	for child in get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var size: Vector3 = child.mesh.size
			if size.x <= 0.65 and size.z <= 0.65 and size.y > 0.6:
				Art.box(self, child.position + Vector3(0, size.y * 0.2, 0), Vector3(size.x + 0.01, 0.13, size.z + 0.01), Color("e9a357"))
