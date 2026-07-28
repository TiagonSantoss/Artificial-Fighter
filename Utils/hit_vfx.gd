class_name HitVFX
extends GPUParticles3D

func play():
	restart()
	emitting = true
	
	await finished
	
	AutoHitVFXPool.release(self)
