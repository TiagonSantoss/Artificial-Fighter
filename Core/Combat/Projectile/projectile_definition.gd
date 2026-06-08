class_name ProjectileDefinition
extends Resource

@export_category("Visuals")
@export var sprite_frames: SpriteFrames
@export var default_animation := "default"
@export var modulate := Color.WHITE
@export var billboard := BaseMaterial3D.BILLBOARD_ENABLED
@export var texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
@export var sprite_scale := Vector3.ONE

@export_category("Movement")
@export var speed := 10.0
@export var gravity := 0.0
@export var drag := 0.0
@export var bounce_count := 0
@export var bounce_factor := 0.7
@export var homing := false
@export var homing_strength := 0.0
@export var lifetime := 0.5

@export_category("Combat")
@export var damage := 10
@export var knockback := 1.0
@export var pierce := 0
@export var explosive_radius := 0.0

@export_category("Collision")
@export var radius := 0.2
#@export var status_effect: StatusEffect MAYBE......
