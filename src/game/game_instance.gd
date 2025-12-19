extends Node


@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var player: Player = $Player


func _ready() -> void:
	player.setup_chunk_manager(chunk_manager)
