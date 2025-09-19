extends Node

const CHUNK_SIZE: int = 64 # Size of each chunk in tiles (chunk is square)
const TILE_SIZE: int = 1 # Size of each tile in world units (pixels)
const LOAD_RADIUS: int = 8 # How many chunks to load around the player
const COLLISION_RADIUS: int = 1 # How many chunks to enable collision for around the player
const RECYCLE_POOL_MAX_SIZE: int = 0 # Max number of chunks to keep in the recycle pool