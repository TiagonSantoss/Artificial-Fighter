class_name CommandRegistry
extends Node

# Register resource short-names mapped to their file paths
const CARD_DATABASE := {
	"itf": "res://assets/items/cards/into_the_fire.tres",
}

const EFFECT_DATABASE := {
	"fire": "res://assets/items/effects/fire.tres",
}


func execute_command(command_text: String, player: Entity) -> String:
	var tokens := command_text.strip_edges().split(" ", false)
	if tokens.is_empty():
		return ""

	var cmd := tokens[0].to_lower()
	var args := tokens.slice(1)

	match cmd:
		"give_card":
			return _cmd_give_card(args, player)
		"give_effect":
			return _cmd_give_effect(args, player)
		"clear_effects":
			return _cmd_clear_effects(player)
		"help":
			return "Available commands: give_card <name>, give_effect <name>, clear_effects, help"
		_:
			return "Unknown command: '%s'. Type 'help' for options." % cmd


func _cmd_give_card(args: Array, player: Entity) -> String:
	if args.is_empty():
		return "Usage: give_card <card_name>"

	var card_id = args[0].to_lower()
	if not CARD_DATABASE.has(card_id):
		return "Card '%s' not found in database. Options: %s" % [card_id, str(CARD_DATABASE.keys())]

	var res_path: String = CARD_DATABASE[card_id]
	var card_def = load(res_path) as CardDefinition

	if card_def == null:
		return "Failed to load card resource at %s" % res_path

	var instance := ItemInstance.new()
	instance.definition = card_def

	# Target HandComponent specifically!
	if player and player.cards_component:
		player.cards_component.hand.add(instance)
		return "Successfully added card '%s' to player hand." % card_id

	return "Player missing CardsComponent!"


func _cmd_give_effect(args: Array, player: Entity) -> String:
	if args.is_empty():
		return "Usage: give_effect <effect_name>"

	var effect_id = args[0].to_lower()
	if not EFFECT_DATABASE.has(effect_id):
		return "Effect '%s' not found. Options: %s" % [effect_id, str(EFFECT_DATABASE.keys())]

	var res_path: String = EFFECT_DATABASE[effect_id]
	var effect_def = load(res_path) as EffectDefinition

	if effect_def == null:
		return "Failed to load effect resource at %s" % res_path

	var instance := ItemInstance.new()
	instance.definition = effect_def

	if player and player.effects_component:
		player.effects_component.effects.add(instance)

		# Emit signal to update UI
		var state := EffectsChangedState.new(player, instance)
		GState.effects_changed.emit(state)

		return "Successfully added effect '%s' to player." % effect_id

	return "Player missing EffectsComponent!"


func _cmd_clear_effects(player: Entity) -> String:
	if player and player.effects_component:
		player.effects_component.effects.contents.clear()

		# Notify both listeners that the lists have cleared
		var effect_state := EffectsChangedState.new(player, null)
		GState.effects_changed.emit(effect_state)

		var card_state := CardsChangedState.new(player, null)
		GState.cards_changed.emit(card_state)

		return "Cleared all effects/cards."
	return "Player missing EffectsComponent!"
