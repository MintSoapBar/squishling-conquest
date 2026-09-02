class_name MagicExplosionVFX
extends MagicVFX

func _ready() -> void:
	for child in get_children():
		if child is CPUParticles3D:
			var particles := child as CPUParticles3D
			particles.emitting = true
