class_name MagicVFXDataPopulator

static func populate() -> void:
	# name, projectile audio, projectile particle, explosion audio, explosion particle
	
	create_standard_magic_data_set("air",
		{
			gravity = Vector3(0, 0, 0),
		},
		
		# projectile
		{
			stream = preload("uid://b7t4rwtyy3upr"),
			volume_db = 7.0,
			pitch_scale = 1.0,
		},
		{
			amount = 16,
			scale_amount_min = 3,
			scale_amount_max = 3,
		},
		
		# explosion
		{
			stream = preload("uid://b51wo72u54jbp"),
			volume = -25,
			pitch_scale = 0.9,
		},
		{
			amount = 6,
			scale_amount_min = 3,
			scale_amount_max = 3,
		},
	)
	
	create_standard_magic_data_set("earth",
		{
			gravity = Vector3(0, -3.0, 0),
		},
		
		# projectile
		{
			stream = preload("uid://b2y451kep3s3x"),
			volume_db = 0.0,
			pitch_scale = 1.0,
		},
		{
			amount = 10,
		},
		
		# explosion
		{
			stream = preload("uid://c3a4wi10tfwlq"),
			volume = -43,
			pitch_scale = 0.7,
		},
		{
			amount = 6,
		},
	)
	
	create_standard_magic_data_set("fire",
		{
			gravity = Vector3(0, 2, 0),
		},
		
		# projectile
		{
			stream = preload("uid://b2y451kep3s3x"),
			volume_db = 0.0,
			pitch_scale = 1.0,
		},
		{
			amount = 16,
			initial_velocity_min = 0.0,
			initial_velocity_max = 2.0,
		},
		
		# explosion
		{
			stream = preload("uid://c2pm5vs11kt7r"),
			volume = -41,
			pitch_scale = 1.5,
		},
		{
			amount = 6,
			initial_velocity_min = 0.0,
			initial_velocity_max = 2.0,
		},
	)
	
	create_standard_magic_data_set("light",
		{
			gravity = Vector3(0, 0, 0),
		},
		
		# projectile
		{
			stream = preload("uid://drpnfsw08bn2n"),
			volume_db = 2.0,
			pitch_scale = 1.2,
		},
		{
			amount = 32,
			randomness = 0.0,
			scale_amount_min = 1.5,
			scale_amount_max = 1.5,
		},
		
		# explosion
		{
			stream = preload("uid://da7iqe6edxb2p"),
			volume = -43,
			pitch_scale = 1.0,
		},
		{
			amount = 6,
			scale_amount_min = 1.5,
			scale_amount_max = 1.5,
		},
	)
	
	MagicVFXData.get_projectile_data("light").add_element_data(
		"mesh", 
		InheritedDictionary.new([], {
			mesh = preload("uid://b0q1odwydy1f3"), 
			material_override = preload("uid://cb4xjagqb7jla"),
		})
	)
	
	create_standard_magic_data_set("poison",
		{
			gravity = Vector3(0, 1, 0),
		},
		
		# projectile
		{
			stream = preload("uid://b7t4rwtyy3upr"),
			volume_db = 7.0,
			pitch_scale = 1.0,
		},
		{
			amount = 12,
			scale_amount_min = 3.0,
			scale_amount_max = 3.0,
		},
		
		# explosion
		{
			stream = preload("uid://b51wo72u54jbp"),
			volume = -25,
			pitch_scale = 0.7,
		},
		{
			amount = 6,
			scale_amount_min = 3.0,
			scale_amount_max = 3.0,
		},
	)
	
	create_standard_magic_data_set("shadow",
		{
			gravity = Vector3(0, 0, 0),
		},
		
		# projectile
		{
			stream = preload("uid://c4ax1tcfwbhy7"),
			volume_db = -3.0,
			pitch_scale = 0.6,
		},
		{
			amount = 8,
			randomness = 0.0,
		},
		
		# explosion
		{
			stream = preload("uid://dvrmq7yxrayay"),
			volume = -40,
			pitch_scale = 0.8,
		},
		{
			amount = 6,
		},
	)
	
	MagicVFXData.get_projectile_data("shadow").add_element_data(
		"mesh", 
		InheritedDictionary.new([], {
			mesh = preload("uid://b0q1odwydy1f3"), 
			material_override = preload("uid://dv5gofgqv5col"),
		})
	)
	
	create_standard_magic_data_set("water",
		{
			gravity = Vector3(0, -10, 0),
			initial_velocity_min = 0.0,
			initial_velocity_max = 3.0,
		},
		
		# projectile
		{
			stream = preload("uid://dpojk73fw5o4d"),
			volume_db = 0.0,
			pitch_scale = 0.5,
		},
		{
			amount = 16,
			scale_amount_min = 2.5,
			scale_amount_max = 2.5,
		},
		
		# explosion
		{
			stream = preload("uid://c43t1u1utpbvu"),
			volume = -33,
			pitch_scale = 1.0,
		},
		{
			amount = 6,
			scale_amount_min = 2.5,
			scale_amount_max = 2.5,
		},
	)


static func create_standard_magic_data_set(magic_name: String, 
	particle_data: Dictionary, 
	projectile_audio_data: Dictionary, projectile_particle_data: Dictionary,
	explosion_audio_data: Dictionary, explosion_particle_data: Dictionary) -> MagicVFXData:
		
	var path = MagicVFX.get_magic_vfx_path(magic_name)
	
	var magic_data := create_magic_data(magic_name)
	var magic_particles_data = magic_data.get_element_data("particles")
	magic_particles_data.replace_dictionary(particle_data)
	
	var curve_path = path + "/" + magic_name + "_particle_scale_curve.tres"
	if ResourceLoader.exists(curve_path):
		magic_particles_data.set_value("scale_amount_curve", load(curve_path))
	
	var ramp_path = path + "/" + magic_name + "_particle_color_ramp.tres"
	if ResourceLoader.exists(ramp_path):
		magic_particles_data.set_value("color_ramp", load(ramp_path))
	
	
	var projectile_data = create_projectile_data(magic_name)
	projectile_data.get_element_data("audio").replace_dictionary(projectile_audio_data)
	projectile_data.get_element_data("particles").replace_dictionary(projectile_particle_data)
	
	var explosion_data = create_explosion_data(magic_name)
	explosion_data.get_element_data("audio").replace_dictionary(explosion_audio_data)
	explosion_data.get_element_data("particles").replace_dictionary(explosion_particle_data)
	
	return magic_data


static func create_magic_data(magic_name: String) -> MagicVFXData:
	var new_magic_data = MagicVFXData.new([
		MagicVFXData.base_magic_vfx_data
	])
	MagicVFXData.data[magic_name] = new_magic_data
	return new_magic_data


static func create_projectile_data(magic_name: String) -> MagicVFXData:
	var new_projectile_data = MagicVFXData.new([
		MagicVFXData.base_projectile_vfx_data, 
		MagicVFXData.data[magic_name]
	])
	MagicVFXData.data[magic_name + "/projectile"] = new_projectile_data
	return new_projectile_data


static func create_explosion_data(magic_name: String) -> MagicVFXData:
	var new_explosion_data = MagicVFXData.new([
		MagicVFXData.base_explosion_vfx_data, 
		MagicVFXData.data[magic_name]
	])
	MagicVFXData.data[magic_name + "/explosion"] = new_explosion_data
	return new_explosion_data
