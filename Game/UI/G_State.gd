extends Node

signal perspective_updated(state: CameraPerspectiveState)  # RefCounted
signal seed_changed(state: SeedChangedState)  # RefCounted
signal effects_changed(state: EffectsChangedState)
signal cards_changed(state: CardsChangedState)
signal controlled_entity_changed(entity: Entity)

signal fmod
