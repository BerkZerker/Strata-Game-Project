extends Node

const CHUNK_SIZE: int = 32 # Size of each chunk in tiles (chunk is square)
const TILE_SIZE: int = 1 # Size of each tile in world units (pixels)
const LOAD_RADIUS: int = 16 # How many chunks to load around the player
const COLLISION_RADIUS: int = 1 # How many chunks to enable collision for around the player
const MAX_CHUNK_UPDATES_PER_FRAME: int = 1 # Max number of chunks to build per frame
