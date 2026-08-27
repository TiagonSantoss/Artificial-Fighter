extends Node

signal perspective_updated(state: CameraPerspectiveState)

signal seed_changed(state: SeedChangedState)

signal effects_changed(state: EffectsChangedState)
signal cards_changed(state: CardsChangedState)

signal controlled_entity_changed(entity: Entity)

signal weapon_changed(state: WeaponState)
signal health_changed(health: float)
signal rank_changed(state: RankState)
signal score_updated(current_score: float, floor_score: float, ceiling_score: float)

signal enemy_damaged(base_points: float)
signal enemy_parried(base_points: float)

signal shop_item_selected(item_node)

signal fmod
