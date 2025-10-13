extends Node

const CHUNK_SIZE: int = 32 # Size of each chunk in tiles (chunk is square)
const LOAD_RADIUS: int = 24 # How many chunks to load around the player
const COLLISION_RADIUS: int = 1 # How many chunks to enable collision for around the player - DEPRECATED
const MAX_CHUNK_UPDATES_PER_FRAME: int = 10 # Max number of chunks to build per frame
