class_name WeaponAudioComponent
extends WeaponComponent

const SFX_BASE_PATH: String = "event:/SFX/Weapon/"


func play_sfx(sfx: String) -> void:
	if not is_instance_valid(weapon.wielder.emitter):
		return

	weapon.wielder.emitter.event_name = SFX_BASE_PATH + sfx

	weapon.wielder.emitter.play_one_shot()
