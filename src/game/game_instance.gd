class_name GameInstance extends Node


@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var player: Player = $Player
@onready var gui_manager: GUIManager = $UILayer/GUIManager


func _ready() -> void:
	player.setup_chunk_manager(chunk_manager)
	gui_manager.setup_chunk_manager(chunk_manager)
