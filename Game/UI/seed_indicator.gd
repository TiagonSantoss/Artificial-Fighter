extends Control

@onready var seed_label: RichTextLabel = $RichTextLabel

@onready var dungeon_manager: Node3D = $"../../Dungeon/DungeonManager"

func _ready() -> void:
	if dungeon_manager:
		dungeon_manager.seed_changed.connect(_on_dungeon_seed_changed)

func _on_dungeon_seed_changed(new_seed) -> void:
	seed_label.text = "Seed: [color=green]" + str(new_seed) + "[/color]"
