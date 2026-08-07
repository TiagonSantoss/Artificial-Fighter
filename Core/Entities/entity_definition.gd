class_name EntityDefinition
extends Resource

enum SpawnGroup { MELEE, RANGED, BOSS }

enum VisualType { SPRITE_3D, MESH_3D, HYBRID }

@export_category("Visual Type")
@export var visual_type: VisualType = VisualType.SPRITE_3D

@export_category("Sprite Settings")
@export var sprite_frames: SpriteFrames
@export var default_animation: String = "idle"
@export var modulate: Color = Color.WHITE
@export var billboard := BaseMaterial3D.BILLBOARD_ENABLED
@export var texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
@export var sprite_scale := Vector3.ONE

@export_category("Mesh Settings")
@export var mesh: Mesh
@export var material_override: Material
@export var mesh_scale := Vector3.ONE

@export_category("Stats")
@export var max_health: int = 100
@export var move_speed: float = 1.5
@export var max_speed: float = 1.2
@export var acceleration: float = 1.0
@export var friction: float = 1.3
@export var jump_force := 6.0

@export_category("Hitbox")
@export var hitbox_size := Vector3(1.0, 1.0, 1.0)
@export var hitbox_shape_override: Shape3D = null
@export var hitbox_offset := Vector3.ZERO

@export_category("Behavior")
@export var controller: Controller

@export_category("Data")
@export var entity_id: int
@export var starting_weapon: WeaponDefinition
@export var team: Entity.Team
@export var spawn_group := SpawnGroup.MELEE


func get_spawn_group_name() -> String:
	match spawn_group:
		SpawnGroup.MELEE:
			return "melee"
		SpawnGroup.RANGED:
			return "ranged"
		SpawnGroup.BOSS:
			return "boss"
	return "melee"
