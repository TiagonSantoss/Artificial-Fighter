extends Control

@onready var seed_label: RichTextLabel = $RichTextLabel


func _ready() -> void:
	GState.seed_changed.connect(_on_dungeon_seed_changed)


func _on_dungeon_seed_changed(new_seed) -> void:
	seed_label.text = "seed: [color=green]" + str(new_seed) + "[/color]"
