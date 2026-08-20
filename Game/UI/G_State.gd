extends Node

signal _perspective_updated(state: CameraPerspectiveState)

signal _seed_changed(state: SeedChangedState)

signal _effects_changed(state: EffectsChangedState)
signal _cards_changed(state: CardsChangedState)

signal _controlled_entity_changed(entity: Entity)

signal _weapon_changed(state: WeaponState)
signal _health_changed(health: float)
signal _rank_changed(state: RankState)
signal _score_updated(current_score: float, floor_score: float, ceiling_score: float)

signal _enemy_damaged(base_points: float)
signal _enemy_parried(base_points: float)

signal _fmod
