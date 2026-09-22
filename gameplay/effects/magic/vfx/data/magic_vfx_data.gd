class_name MagicVFXData

static var magics_vfx_path: String = (MagicVFXData as GDScript).resource_path \
	.replace("data/magic_vfx_data.gd", "magics/")

static var base_magic_vfx_data: MagicVFXData
static var base_projectile_vfx_data: MagicVFXData
static var base_explosion_vfx_data: MagicVFXData

var audio_data: InheritedDictionary
var particle_data: InheritedDictionary


static func _static_init() -> void:
	base_magic_vfx_data = MagicVFXData.new()
	base_magic_vfx_data.audio_data = InheritedDictionary.new([], {
		stream = preload("uid://b2y451kep3s3x"),
		volume_db = 0.0,
		unit_size = 10.0,
		pitch_scale = 1.0,
	})
	
	base_magic_vfx_data.particle_data = InheritedDictionary.new([], {
		mesh = preload("uid://c1tly4xqwqx5o"),
		amount = 16,
		explosiveness = 0,
		gravity = Vector3.ZERO,
		scale_amount_curve = preload("uid://cdh6m8phc5p36"),
		color_ramp = preload("uid://lavx1vvvx0dj"),
	})
	
	base_projectile_vfx_data = MagicVFXData.new()
	base_projectile_vfx_data.audio_data = InheritedDictionary.new([], {
		unit_size = 5.0,
	})
	base_projectile_vfx_data.particle_data = InheritedDictionary.new()
	
	base_explosion_vfx_data = MagicVFXData.new()
	base_explosion_vfx_data.audio_data = InheritedDictionary.new()
	base_explosion_vfx_data.particle_data = InheritedDictionary.new([], {
		explosiveness = 0.85,
	})


func _init(parents: Array[MagicVFXData] = []) -> void:
	var audio_parents = []
	var particle_parents = []
	
	for parent in parents:
		audio_parents.append(parent.audio_data)
		particle_parents.append(parent.particle_data)
	
	audio_data = InheritedDictionary.new(particle_parents)
	particle_data = InheritedDictionary.new(particle_parents)
