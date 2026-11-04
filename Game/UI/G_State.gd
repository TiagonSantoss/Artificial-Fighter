extends Node

signal perspective_updated(state: CameraPerspectiveState)

signal seed_changed(state: SeedChangedState)

signal effects_changed(state: EffectsChangedState)
signal cards_changed(state: CardsChangedState)

signal controlled_entity_changed(entity: Entity)

signal weapon_changed(state: WeaponState)

signal health_changed(entity_id: int, health: float)
signal rank_changed(entity_id: int, new_rank: int, old_rank: int)
signal player_damaged(entity_id: int, iframe_duration: float)

signal score_updated(current_score: float, floor_score: float, ceiling_score: float)

signal enemy_damaged(source_id: int, hit_count: int)
signal enemy_parried(parried_enemies_amount: int)

signal accessories_changed(state: AccessoriesChangedState)

signal encounter_ended(final_rank: int)

signal shop_item_selected(item_node)
signal shop_activation_requested(is_active: bool)

signal fmod

signal ammo_bound(ammo: AxisAmmo)

var current_ammo: AxisAmmo


func bind_ammo(new_ammo: AxisAmmo) -> void:
	current_ammo = new_ammo
	ammo_bound.emit(new_ammo)


var current_perspective: CameraPerspectiveState = CameraPerspectiveState.new(
	CameraPerspectiveState.Axis.X_NEGATIVE
)
