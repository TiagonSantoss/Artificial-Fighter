class_name ProjectileDefinition
extends Resource

@export_category("Movement")
@export var speed: float = 25.0
@export var gravity: float = 0.0
@export var drag: float = 0.0
@export var lifetime: float = 3.0

@export_category("Combat")
@export var damage: float = 10.0
@export var knockback: float = 1.0
@export var pierce: int = 0
@export var bounce_count: int = 0
@export var radius: float = 0.2
@export var stun_duration: float = 0.2

@export_category("Rendering (Atlas)")
@export var frame_size := Vector2i(100, 60)
@export var atlas_column := 0
@export var atlas_row := 0

@export_category("Visual")
@export var scale: Vector3 = Vector3.ONE
@export var color: Color = Color.WHITE
@export var emissive_strength: float = 1.0
@export var billboard := true

@export_category("Behavior Flags")
@export var rotates_to_velocity := false
@export var additive_blend := true
