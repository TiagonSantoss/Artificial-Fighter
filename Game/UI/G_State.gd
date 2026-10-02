extends Node

signal perspective_updated(state: CameraPerspectiveState)

signal seed_changed(state: SeedChangedState)

signal effects_changed(state: EffectsChangedState)
signal cards_changed(state: CardsChangedState)

signal controlled_entity_changed(entity: Entity)

signal weapon_changed(state: WeaponState)
signal health_changed(health: float)

signal rank_changed(new_rank: int, old_rank: int)

signal score_updated(current_score: float, floor_score: float, ceiling_score: float)

signal enemy_damaged(hit_count: int)
signal enemy_parried(parried_enemies_amount: int)
signal player_damaged(iframe_duration: float)

signal encounter_ended(final_rank: int)

signal shop_item_selected(item_node)
signal shop_activation_requested(is_active: bool)

signal fmod

var current_perspective: CameraPerspectiveState = CameraPerspectiveState.new(
	CameraPerspectiveState.Axis.X_NEGATIVE
)
