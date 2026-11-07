class_name Game
extends Node3D

signal all_characters_dead

const ENTITY_SCENE = preload("res://Core/Entities/Entity.tscn")
const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 3
const LAYER_BARRIER := 10
const DEATH_SLOWMO_SCALE := 0.25
const DEATH_SLOWMO_TIME := 1.6  # real seconds, not scaled

const GAME_OVER_SCENE := preload("res://Game/UI/game_over.tscn")

static var player: Entity
static var companion: Entity
static var instance: Game

@export var enemy_pool: Array[EntityDefinition]
@export var npc_pool: Array[EntityDefinition]

var player_definition: EntityDefinition = preload(
	"res://assets/definitions/entities/actors/player_definition.tres"
)
var companion_definition: EntityDefinition = preload(
	"res://assets/definitions/entities/actors/rat_definition.tres"
)

var controlled_entity: Entity:
	get:
		return _controlled_entity
	set(value):
		_controlled_entity = value
		GState.controlled_entity_changed.emit(controlled_entity)

var chunk_manager: ChunkManager:
	set(value):
		chunk_manager = value
		if (
			chunk_manager != null
			and not chunk_manager.active_room_changed.is_connected(_on_active_room_changed)
		):
			chunk_manager.active_room_changed.connect(_on_active_room_changed)

var entity_camera_pivot: Marker3D
var active_room_pivot: DynamicRotatingCameraPivot = null

var entities: Node3D
var player_spawn: Marker3D
var emitter: FmodEventEmitter3D
var ui_emitter: FmodEventEmitter2D
var camera_rig: Camera3D
var floors_reached := 1
var is_restarting := false
# var marker: Marker3D
var wallet := PlayerWallet.new()
var can_swap := true

var _controlled_entity: Entity
var _companion_entity: Entity
var _game_over_screen: GameOverScreen

var _intro_played := false
var _game_over := false


func _ready() -> void:
	instance = self
	call_deferred("_init_camera")

	GState.fmod.connect(_boss_music)


func play_intro() -> void:
	if _intro_played:
		return
	_intro_played = true

	add_money("cc", 1)  # looks like debug, but move it here if it belongs to a new run

	await get_tree().create_timer(1.0).timeout
	get_tree().paused = true

	(
		DialogueManager
		. show_messages(
			[
				"Ola, sou a {pause=0.5}[wave amp=50 freq=2][color=pink]Gizmo-chan[/color][/wave]. Estou aqui para te ajudar. Vamos Começar? Aperte ENTER caso esteja no teclado, {pause=0.3} ou A (X no playstation) se estiver no controle.",
				"Nesse jogo, {pause=0.3} voce precisa sobreviver à {pause=0.5}[shake][color=808080]masmorra[/color][/shake]\n pegando itens.",
				"Vamos para os {pause=0.5}[shake]controles:[/shake]",
				"O pulo é {pause=0.2}[rainbow][wave amp=50 freq=2]automático[/wave][/rainbow], não é necessário pular.\n",
				"Aperte {pause=0.5}[rainbow][wave amp=50 freq=2]Q[/wave][/rainbow] ou {pause=0.5}[rainbow][wave amp=50 freq=2]E[/wave][/rainbow] para {pause=0.2}[tornado]girar a camera[/tornado]\n se estiver usando um controle, use RB ou LB.",
				"Use o {pause=0.5}[wave]botão esquerdo do mouse[/wave] para atacar, caso esteja no controle,{pause=0.3} apenas mire on o [wave]analogico direito.[/wave]",
				"Aperte TAB ou LT para trocar [tornado]entre o pinguin e o rato.[/tornado]",
				"Para usar sua {pause=0.3}[tornado]habilidade especial,[/tornado] aperte botão direito do mouse, {pause=0.3} ou RT, {pause=0.3} se estiver no controle.",
				"Lembre-se de sempre prestar atenção na barra embaixo no minimapa, {pause=0.3} ela mostra suas [shake]'balas'[/shake]. \n as balas funcionam por eixo (X ou Z), quando voce atira elas mudam de eixo.",
				"Por enquanto é só isso que posso lhe ensinar, {pause=0.3}. {pause=0.3}. {pause=0.3}. sinta-se avontade para avançar e {pause=0.5}[shake]entrar na porta[/shake] para começar o jogo."
			]
		)
	)


func _boss_music():
	print("SETTING GLOBAL PARAMETER")
	FmodServer.set_global_parameter_by_name("MusicType", 1)


func _process(_delta: float) -> void:
	if not is_instance_valid(camera_rig):
		return


func _on_active_room_changed(room_data: Variant) -> void:
	if room_data == null or not is_instance_valid(camera_rig):
		return

	var physical_room_node: Node3D = null
	var _room_def: RoomDefinition = null

	if room_data is RoomInstance:
		physical_room_node = room_data.node
		_room_def = room_data.definition
	elif "node" in room_data:
		physical_room_node = room_data.node
		if "definition" in room_data:
			_room_def = room_data.definition

	if not is_instance_valid(physical_room_node):
		return

	var new_pivot := (
		physical_room_node.find_child("CameraPivot", true, false) as DynamicRotatingCameraPivot
	)

	if not is_instance_valid(new_pivot):
		return

	if is_instance_valid(active_room_pivot):
		new_pivot.rotation.y = active_room_pivot.rotation.y
		new_pivot.target_rotation_y = active_room_pivot.target_rotation_y
		new_pivot.is_rotating = active_room_pivot.is_rotating

		new_pivot.base_camera_size = active_room_pivot.base_camera_size
		new_pivot.max_extra_size = active_room_pivot.max_extra_size
		new_pivot.follow_speed = active_room_pivot.follow_speed

		active_room_pivot.deactivate()

	active_room_pivot = new_pivot

	var target_size := Vector2(40.0, 40.0)
	# if room_def and room_def.size != Vector2i.ZERO:
	# 	target_size = Vector2(room_def.size)

	active_room_pivot.set_room(room_data)
	active_room_pivot.activate(target_size)


func _init_camera() -> void:
	if is_instance_valid(camera_rig) and is_instance_valid(player_spawn):
		camera_rig.global_position = player_spawn.global_position


func flash_screen_overlay(color: Color, duration: float) -> void:
	# 1. Create a top-level CanvasLayer so it covers the whole screen
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100  # Render on top of all HUD/UI elements
	add_child(canvas_layer)

	# 2. Create the full-screen color tint
	var overlay := ColorRect.new()
	overlay.color = color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block gameplay input
	canvas_layer.add_child(overlay)

	# 3. Tween the overlay alpha from initial color down to completely invisible
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration)

	# 4. Clean up nodes when the animation completes
	tween.finished.connect(canvas_layer.queue_free)


func add_money(currency: StringName, amount: int) -> void:
	wallet.add(currency, amount)


func try_spend(currency: StringName, cost: int) -> bool:
	return wallet.spend(currency, cost)


func rotate_by(degrees: float) -> void:
	if is_instance_valid(active_room_pivot):
		active_room_pivot.rotate_by(degrees)


func get_camera_forward() -> Vector3:
	if not is_instance_valid(active_room_pivot):
		return Vector3(0, 0, -1)
	return Vector3(0, 0, -1).rotated(Vector3.UP, active_room_pivot.rotation.y)


func get_camera_right() -> Vector3:
	if not is_instance_valid(active_room_pivot):
		return Vector3(1, 0, 0)
	return Vector3(1, 0, 0).rotated(Vector3.UP, active_room_pivot.rotation.y)


func get_current_entity() -> Entity:
	if is_instance_valid(_controlled_entity) and _controlled_entity.controller is PlayerController:
		return _controlled_entity
	return _companion_entity


func is_current_entity(entity) -> bool:
	return is_instance_valid(entity) and entity == get_current_entity()


func get_living_characters() -> Array[Entity]:
	var result: Array[Entity] = []
	for e in [player, companion]:
		var alive := _alive(e)
		if alive != null:
			result.append(alive)
	return result


func _alive(entity) -> Entity:
	if is_instance_valid(entity) and not entity.is_queued_for_deletion():
		return entity
	return null


func revive_missing_characters(pos: Vector3) -> void:
	var player_alive := _alive(player) != null
	var companion_alive := _alive(companion) != null
	if player_alive and companion_alive:
		return

	_game_over = false

	if not player_alive and not companion_alive:
		spawn_player(pos)  # becomes the controlled entity
		spawn_companion(pos + Vector3(1.0, 0.0, 0.0))
	elif not companion_alive:
		spawn_companion(pos + Vector3(1.0, 0.0, 0.0))  # follows the living player
	else:
		# player is dead, companion is alive and controlled: revive as follower
		var revived := spawn_player(pos)
		var follow := CompanionController.new()
		follow.follow_target = companion
		revived.controller = follow
		controlled_entity = companion  # setter re-emits and rebinds ammo
		_companion_entity = revived

	_retarget_enemies()
	update_accessories_state()


func _forget_entity(entity) -> void:
	if player == entity:
		player = null
	if companion == entity:
		companion = null
	if _controlled_entity == entity:
		_controlled_entity = null
	if _companion_entity == entity:
		_companion_entity = null


func swap_characters(force := false) -> void:
	if not can_swap and not force:
		return

	var a := _alive(player)
	var b := _alive(companion)
	var current := _alive(_controlled_entity)

	if a == null and b == null:
		_controlled_entity = null
		_companion_entity = null
		_on_all_characters_dead()
		return

	var next: Entity
	if current == null:
		next = a if a != null else b  # controlled one died, hand over
	elif a != null and b != null:
		next = b if current == a else a  # normal swap
	else:
		_companion_entity = null  # the follower died, keep control
		return

	can_swap = false

	var follower: Entity = b if next == a else a  # may be null

	next.controller = PlayerController.new()
	_controlled_entity = next

	if follower != null:
		var follow_controller := CompanionController.new()
		follow_controller.follow_target = next
		follower.controller = follow_controller
	_companion_entity = follower

	_retarget_enemies()
	GState.controlled_entity_changed.emit(_controlled_entity)
	update_accessories_state()

	await get_tree().create_timer(0.4).timeout
	can_swap = true


func _retarget_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.controller != null and "target" in enemy.controller:
			enemy.controller.target = _controlled_entity


func _on_all_characters_dead() -> void:
	if _game_over:
		return
	_game_over = true
	_retarget_enemies()
	all_characters_dead.emit()

	Engine.time_scale = DEATH_SLOWMO_SCALE
	await get_tree().create_timer(DEATH_SLOWMO_TIME, true, false, true).timeout

	Engine.time_scale = 1.0
	get_tree().paused = true
	_get_game_over_screen().open(floors_reached)


func _get_game_over_screen() -> GameOverScreen:
	if not is_instance_valid(_game_over_screen):
		_game_over_screen = GAME_OVER_SCENE.instantiate() as GameOverScreen
		_game_over_screen.restart_requested.connect(restart_run)
		add_child(_game_over_screen)
	return _game_over_screen


func restart_run() -> void:
	if is_restarting:
		return
	is_restarting = true

	Engine.time_scale = 1.0
	get_tree().paused = false  # SceneManager's tweens don't run while paused
	_get_game_over_screen().close()
	GState.boss_fight_changed.emit([])  # hides the boss bar

	await SceneManager.cover_screen()

	reset_run()
	RunManager.opened_chests.clear()  # otherwise chests stay open in the new run
	get_tree().reload_current_scene()

	# Give the new scene time to build (DungeonManager waits a frame, then generates)
	for _i in 3:
		await get_tree().process_frame
	is_restarting = false

	await SceneManager.reveal_screen()


func reset_run() -> void:
	_game_over = false
	can_swap = true
	player = null
	companion = null
	_controlled_entity = null
	_companion_entity = null
	active_room_pivot = null
	floors_reached = 1
	wallet = PlayerWallet.new()


func update_accessories_state() -> void:
	var entity = get_current_entity()
	var items: Array[ItemInstance] = []

	if entity != null and entity.get("accessories_component") != null:
		items = entity.accessories_component.get_accessories()

	var new_state = AccessoriesChangedState.new(items)
	GState.accessories_changed.emit(new_state)


func spawn_player(pos: Vector3) -> Entity:
	var listener3D = FmodListener3D.new()
	player = spawn_entity(player_definition, pos)
	controlled_entity = player
	player.add_to_group("player")
	player.add_child(listener3D)

	player.tree_exited.connect(_forget_entity.bind(player))

	# player.collision_layer = 1
	return player


func spawn_enemy(pos: Vector3, definition: EntityDefinition = null) -> Entity:
	if definition == null:
		definition = enemy_pool.pick_random()

	var enemy := spawn_entity(definition, pos)
	enemy.controller.target = _alive(_controlled_entity)
	enemy.add_to_group("enemies")

	return enemy


func spawn_companion(pos: Vector3) -> Entity:
	var local_companion := spawn_entity(companion_definition, pos)
	_companion_entity = local_companion
	companion = local_companion
	local_companion.controller.follow_target = _alive(player)

	local_companion.add_to_group("player")
	local_companion.tree_exited.connect(_forget_entity.bind(local_companion))
	return local_companion


func spawn_npc(pos: Vector3, definition: EntityDefinition) -> Entity:
	return spawn_entity(definition, pos)


func spawn_entity(definition: EntityDefinition, pos: Vector3) -> Entity:
	var entity: Entity = ENTITY_SCENE.instantiate()

	if entities != null:
		entities.add_child(entity)
	else:
		push_warning("Entities container is missing or not ready! Spawning in current_scene.")
		get_tree().current_scene.add_child(entity)

	entity.setup(pos, definition)
	configure_entity_collision(entity)

	return entity


func configure_entity_collision(entity: Entity) -> void:
	entity.collision_layer = 0
	entity.collision_mask = 0

	entity.set_collision_mask_value(LAYER_WORLD, true)
	entity.set_collision_mask_value(LAYER_BARRIER, true)

	match entity.team:
		Entity.Team.PLAYER:
			entity.set_collision_layer_value(LAYER_PLAYER, true)

		Entity.Team.ENEMY:
			entity.set_collision_layer_value(LAYER_ENEMY, true)

		Entity.Team.ALLY:
			entity.set_collision_layer_value(LAYER_PLAYER, true)
