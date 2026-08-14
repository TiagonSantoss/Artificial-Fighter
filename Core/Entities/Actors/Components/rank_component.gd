class_name RankComponent
extends Node

signal rank_changed(new_rank: RankDefinition)

@export var available_ranks: Array[RankDefinition]

var current_score: float = 0.0
var active_rank: RankDefinition = null


func _ready() -> void:
	if available_ranks.size() > 0:
		active_rank = available_ranks[0]


# Call this whenever the score changes (either from hits going UP or time going DOWN)
func evaluate_rank() -> void:
	var new_rank = active_rank

	for rank in available_ranks:
		if current_score >= rank.score_threshold:
			new_rank = rank

	if new_rank != active_rank:
		active_rank = new_rank
		rank_changed.emit(active_rank)
