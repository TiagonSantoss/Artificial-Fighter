class_name EntityDefinition
extends Resource

@export_category("Visuals")
@export var texture: AtlasTexture
@export var billboard = BaseMaterial3D.BILLBOARD_ENABLED
@export var texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
@export_color_no_alpha var color: Color = Color.WHITE
