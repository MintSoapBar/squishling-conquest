class_name MagicVFXData

static var magics_vfx_path: String = (MagicVFXData as GDScript).resource_path \
	.replace("data/magic_vfx_data.gd", "magics/")

static var data: Dictionary = {}

static var base_magic_vfx_data: MagicVFXData
static var base_projectile_vfx_data: MagicVFXData
static var base_explosion_vfx_data: MagicVFXData

var parents: Array[MagicVFXData]
var element_data: Dictionary[String, InheritedDictionary]

static func _static_init() -> void:
	base_magic_vfx_data = MagicVFXData.new()
	base_magic_vfx_data.add_element_data(
		"audio", 
		InheritedDictionary.new([], {
			stream = null,
			volume_db = 0.0,
			unit_size = 10.0,
			pitch_scale = 1.0,
			autoplay = true,
		})
	)
	
	base_magic_vfx_data.add_element_data(
		"particles", 
		InheritedDictionary.new([], {
			mesh = preload("uid://c1tly4xqwqx5o"),
			amount = 8,
			
			one_shot = false,
			explosiveness = 0.0,
			randomness = 0.0,
			lifetime_randomness = 0.0,
			
			emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT,
			emission_sphere_radius = 0.5,
			
			direction = Vector3.RIGHT,
			spread = 45.0,
			
			initial_velocity_min = 0.0,
			initial_velocity_max = 0.0,
			
			gravity = Vector3.ZERO,
			
			angle_min = 0.0,
			angle_max = 0.0,
			
			scale_amount_min = 1.0,
			scale_amount_max = 1.0,
			scale_amount_curve = preload("uid://cdh6m8phc5p36"),
			
			color_ramp = null,
		})
	)
	
	base_projectile_vfx_data = MagicVFXData.new()
	base_projectile_vfx_data.add_element_data(
		"audio", 
		InheritedDictionary.new([], {
			unit_size = 5.0,
		})
	)
	base_projectile_vfx_data.add_element_data(
		"particles", 
		InheritedDictionary.new([], {
			amount = 16,
			randomness = 1.0,
			lifetime_randomness = 0.5,
			direction = Vector3.UP,
			spread = 180.0,
			angle_min = 0.0,
			angle_max = 360.0,
			scale_amount_min = 2.0,
			scale_amount_max = 2.0,
		})
	)
	
	base_explosion_vfx_data = MagicVFXData.new()
	base_explosion_vfx_data.add_element_data(
		"audio", 
		InheritedDictionary.new([], {
			unit_size = 300.0,
		})
	)
	base_explosion_vfx_data.add_element_data(
		"particles", 
		InheritedDictionary.new([], {
			amount = 6,
			one_shot = true,
			explosiveness = 0.85,
			randomness = 1.0,
			lifetime_randomness = 0.5,
			emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE,
			direction = Vector3.UP,
			spread = 180.0,
			angle_min = 0.0,
			angle_max = 360.0,
			scale_amount_min = 2.0,
			scale_amount_max = 2.0,
		})
	)
	
	
	MagicVFXDataPopulator.populate()


static func get_magic_data(magic_name: String) -> MagicVFXData:
	var magic_data = data.get(magic_name)
	assert(magic_data, "MagicVFXData doesn't exist for magic '%s'" % magic_name)
	
	return magic_data


static func get_projectile_data(magic_name: String) -> MagicVFXData:
	var projectile_data = data.get(magic_name + "/projectile", null)
	if projectile_data:
		return projectile_data
	return get_magic_data(magic_name)


static func get_explosion_data(magic_name: String) -> MagicVFXData:
	var explosion_data = data.get(magic_name + "/explosion", null)
	if explosion_data:
		return explosion_data
	return get_magic_data(magic_name)


func _init(_parents: Array[MagicVFXData] = []) -> void:
	parents = _parents
	parents.make_read_only()
	
	for parent in parents:
		for parent_element_name in parent.element_data:
			var cur_element: InheritedDictionary = element_data.get_or_add(
				parent_element_name, InheritedDictionary.new())
			cur_element.add_parent(parent.element_data[parent_element_name])


func add_element_data(element_name: String, new_element_data: InheritedDictionary):
	element_data[element_name] = new_element_data


func get_element_data(element_name: String) -> InheritedDictionary:
	return element_data[element_name]
