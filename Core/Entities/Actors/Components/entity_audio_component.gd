class_name EntityAudioComponent
extends EntityComponent

const SFX_BASE_PATH: String = "event:/SFX/Entity/"


func play_sfx(sfx: String) -> void:
	if not is_instance_valid(entity.emitter):
		return

	entity.emitter.event_name = SFX_BASE_PATH + sfx

	entity.emitter.play_one_shot()
