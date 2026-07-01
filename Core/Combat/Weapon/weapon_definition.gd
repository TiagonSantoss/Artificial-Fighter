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

@export_category("Stats")
@export var damage_multiplier := 1.0
@export var knockback_multiplier := 1.0
@export var speed_multiplier := 1.0
@export var fire_rate := 1.0
@export var pierce_multiplier := 0.0
@export var recoil := 1.0
@export var spread := 1.0
@export var projectile_count := 1

@export_category("Combat")
@export var is_melee: bool = false
@export var default_behaviors: BehaviorDefinition
@export_group("Attack Types")
@export var projectile: ProjectileDefinition
@export var melee: MeleeDefinition
