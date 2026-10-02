class_name RankComponent
extends EntityComponent

@export var max_rank: int = 11
var current_rank: int = -1  # Starts at -1 (hidden)


func add_hits(amount: int = 1) -> void:
	var old_rank = current_rank
	var starting_rank = max(0, current_rank)

	# Calculate the new rank instantly
	current_rank = min(starting_rank + amount, max_rank)

	if current_rank != old_rank:
		# Emit both the new rank and old rank so the UI knows the full jump
		GState.rank_changed.emit(current_rank, old_rank)


func reset_rank() -> void:
	var old_rank = current_rank
	current_rank = -1

	if current_rank != old_rank:
		GState.rank_changed.emit(current_rank, old_rank)


func finish_encounter() -> void:
	GState.encounter_ended.emit(max(0, current_rank))
	reset_rank()
