class_name MeleeDefinition
extends Resource

@export_category("Visuals")
@export var sprite_frames: SpriteFrames
@export var default_animation := "default"
@export var modulate := Color.WHITE
@export var billboard := BaseMaterial3D.BILLBOARD_ENABLED
@export var texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
@export var sprite_scale := Vector3.ONE

@export_category("Movement")
@export var speed := 1.0
@export var lifetime := 0.2

@export_category("Combat")
@export var damage := 10
@export var knockback := 1.0
@export var status_effect: EffectDefinition

@export_category("Collision")
@export var radius := 0.2
