class_name DirectionalEffectsComponent
extends EntityComponent

enum Slot {
	POS_X,
	NEG_X,
	POS_Y,
	NEG_Y
}

var slots := {
	Slot.POS_X: null,
	Slot.NEG_X: null,
	Slot.POS_Y: null,
	Slot.NEG_Y: null
}

var cooldowns := {}

func get_camera_slot() -> Slot:
	var angle := rad_to_deg(Game.instance.current_rotation_y)
	
	angle = wrapf(angle, 0.0, 360.0)
	angle = round(angle / 90.0) * 90.0
	
	match int(angle):
		0:
			return Slot.POS_Y
		
		90:
			return Slot.POS_X
		
		180:
			return Slot.NEG_Y
		
		270:
			return Slot.NEG_X
	
	return Slot.POS_Y

func _process(delta):
	print(get_camera_slot())
