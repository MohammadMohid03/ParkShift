extends RefCounted
## Five readable atmospheric setups, using one sun and standard distance fog.
static func environment(district: int) -> Environment:
	var env := Environment.new()
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = [Color("6f94ab"),Color("74899b"),Color("5c8caf"),Color("72909d"),Color("33445f")][district]
	material.sky_horizon_color = [Color("e8ddbf"),Color("c4ced3"),Color("c8e4e7"),Color("ccd3d9"),Color("d29975")][district]
	material.ground_bottom_color = Color("354049")
	material.ground_horizon_color = material.sky_horizon_color
	sky.sky_material = material
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = [Color("e9e2d1"),Color("d8e0e6"),Color("d8ebf2"),Color("cfd8e0"),Color("becbdf")][district]
	env.ambient_light_energy = [0.50,0.52,0.55,0.55,0.64][district]
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.fog_enabled = true
	env.fog_light_color = material.sky_horizon_color
	env.fog_density = 0.0007 if district==2 else 0.0010
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return env

static func configure_sun(sun: DirectionalLight3D, district: int) -> void:
	sun.rotation_degrees = [Vector3(-43,-25,0),Vector3(-52,35,0),Vector3(-37,-55,0),Vector3(-58,-15,0),Vector3(-24,-40,0)][district]
	sun.light_color = [Color("fff0d8"),Color("eff3ff"),Color("eef8ff"),Color("fff8e8"),Color("ffc38a")][district]
	sun.light_energy = [0.85,0.75,0.9,0.85,0.65][district]
	sun.directional_shadow_max_distance = 70
	sun.shadow_bias = 0.045
	sun.shadow_normal_bias = 1.0
