extends RefCounted
## Shared PBR surfaces. World-space mapping keeps texel density stable on all arenas.
static var cache: Dictionary = {}
static func surface(kind: String, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := kind + str(tint)
	if cache.has(key): return cache[key]
	var colors := {"asphalt":Color.WHITE,"concrete":Color("aaa99e"),"brick":Color("9b6a50"),"plaster":Color("d0cbb8"),"metal":Color("616b6c"),"glass":Color("344f59"),"paint":Color("e3dfc5"),"wood":Color("8b7350"),"grass":Color("687255")}
	var mat := StandardMaterial3D.new()
	mat.resource_name = "Environment_" + kind
	mat.albedo_color = colors.get(kind,Color.WHITE) * tint
	mat.roughness = 0.9
	if kind == "metal":
		mat.metallic = 0.65
		mat.roughness = 0.46
	elif kind == "glass":
		# Opaque architectural glass avoids sorting/overdraw on mobile.
		mat.metallic = 0.5
		mat.roughness = 0.22
	elif kind == "paint":
		mat.roughness = 0.68
	elif kind == "asphalt":
		mat.albedo_texture = load("res://assets/environment/asphalt_albedo.png")
		mat.roughness = 0.94
	else:
		var noise := FastNoiseLite.new()
		noise.seed = 4913
		noise.frequency = 0.08 if kind == "concrete" else 0.14
		noise.fractal_octaves = 3
		var texture := NoiseTexture2D.new()
		texture.width = 256
		texture.height = 256
		texture.seamless = true
		texture.noise = noise
		var ramp := Gradient.new()
		ramp.colors = PackedColorArray([Color(0.82,0.82,0.82), Color.WHITE])
		texture.color_ramp = ramp
		mat.albedo_texture = texture
	if kind in ["asphalt","concrete","brick","plaster"]:
		var grain := FastNoiseLite.new()
		grain.seed = 817
		grain.frequency = 0.32
		var normal := NoiseTexture2D.new()
		normal.width = 256
		normal.height = 256
		normal.seamless = true
		normal.as_normal_map = true
		normal.bump_strength = 0.65
		normal.noise = grain
		mat.normal_enabled = true
		mat.normal_texture = normal
		mat.normal_scale = 0.16
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * (0.25 if kind == "asphalt" else 0.42)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	cache[key] = mat
	return mat
