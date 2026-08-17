class_name RankComponent
extends EntityComponent

@export var available_ranks: Array[RankDefinition]
@export var decay_rate: float = 15.0  # How many points you lose per second!

var current_score: float = 0.0
var active_rank: RankDefinition = null


func _ready() -> void:
	if available_ranks.size() > 0:
		active_rank = available_ranks[0]


# NEW: This runs every single frame to drain the score
func _process(delta: float) -> void:
	if current_score > 0:
		# Subtract points based on time
		current_score -= decay_rate * delta

	# THE FIX: Clamp it so it NEVER goes below 0 BEFORE evaluating
	current_score = max(0.0, current_score)

	evaluate_rank()


func add_points(base_amount: float) -> void:
	var current_multiplier = 1.0

	# 1. Check if we have an active rank to pull a multiplier from
	if active_rank != null:
		current_multiplier = active_rank.point_multiplier

	# 2. Multiply the incoming points!
	var total_earned = base_amount * current_multiplier

	# 3. Add it to the score
	current_score += total_earned

	# 4. Instantly evaluate the rank so the UI updates the exact moment you get points
	evaluate_rank()


func evaluate_rank() -> void:
	current_score = max(0.0, current_score)
	# 1. Safety check
	if active_rank == null:
		if available_ranks.size() > 0 and available_ranks[0] != null:
			active_rank = available_ranks[0]
		else:
			return

	var new_rank_index = 0
	var new_rank = active_rank

	# 2. Find the correct rank based on the current score
	for i in range(available_ranks.size()):
		var rank = available_ranks[i]
		if rank == null:
			continue

		if current_score >= rank.score_threshold:
			new_rank = rank
			new_rank_index = i

	# 3. Handle Rank Changes (Both UP and DOWN)
	if new_rank != active_rank:
		var old_rank = active_rank
		active_rank = new_rank
		var payload = RankState.new(new_rank, old_rank)
		GState.rank_changed.emit(payload)

	# 4. Progress Bar Logic
	var floor_score = new_rank.score_threshold
	var ceiling_score = floor_score

	if new_rank_index + 1 < available_ranks.size():
		var next_rank = available_ranks[new_rank_index + 1]
		if next_rank != null:
			ceiling_score = next_rank.score_threshold

	# 5. Emit the continuous progress to the UI
	GState.score_updated.emit(current_score, floor_score, ceiling_score)
