class_name RankDefinition
extends Resource

enum RankTier { D, C, B, A, A_PLUS, A_PLUS_PLUS, S, S_PLUS, S_PLUS_PLUS, GIZMO }

@export var tier: RankTier = RankTier.D
@export var display_name: String = "D"
@export var multiplier: float = 1.0
@export var color: Color = Color.WHITE
@export var score_threshold: float = 0.0


func get_sort_value() -> int:
	return tier
