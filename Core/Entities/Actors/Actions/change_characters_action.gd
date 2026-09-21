class_name ChangeCharactersAction
extends Action


func execute(_entity, _delta):
	GameAutoLoad.swap_characters()
	# print(GameAutoLoad.get_entity().entity_id)
