class_name WeaponDefinition
extends Resource

@export_category("Visuals")
@export var sprite_frames: SpriteFrames
@export var default_animation := "default"
@export var modulate := Color.WHITE
@export var billboard := BaseMaterial3D.BILLBOARD_ENABLED
@export var texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
@export var sprite_scale := Vector3.ONE
@export var sprite_offset := Vector3.ZERO
@export var sprite_rotation_offset: float = 0.0

@export_category("Stats")
@export var damage_multiplier := 1.0
@export var knockback_multiplier := 1.0
@export var speed_multiplier := 1.0
@export var fire_rate := 1.0
@export var pierce_multiplier := 0.0
@export var recoil := 1.0
@export var spread := 1.0
@export var projectile_count := 1

@export_category("Audio")
@export var shoot_sound: String
@export var reload_sound: String
#@export var empty_sound: AudioStream MAYBE

@export_category("Combat")
@export var is_melee: bool = false
@export var default_behaviors: Array[BehaviorDefinition]
@export var projectile_size_multiplier: float = 1.0
@export_group("Attack Types")
@export var projectile: ProjectileDefinition
@export var melee: MeleeDefinition
