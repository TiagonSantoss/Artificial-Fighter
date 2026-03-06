class_name EntityDefinition
extends Resource

@export_category("Visual")
@export var sprite_frames: SpriteFrames
@export var default_animation: String = "idle"
@export var modulate: Color = Color.WHITE
@export var billboard := BaseMaterial3D.BILLBOARD_ENABLED
@export var texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

@export_category("Stats")
@export var max_health: int = 3
@export var move_speed: float = 3.0
@export var max_speed: float = 10.0
@export var acceleration: float = 1.0
@export var friction: float = 1.3

@export_category("Behavior")
@export var controller: Controller

@export_category("Data")
@export var entity_id: int
