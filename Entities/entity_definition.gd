class_name EntityDefinition
extends Resource

@export_category("Visual")
@export var texture: AtlasTexture
@export var color: Color = Color.WHITE

@export_category("Stats")
@export var max_health: int = 3

@export_category("Behavior")
@export var controller: Controller
