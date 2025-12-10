extends Node

const CHUNK_SIZE: int = 32 # Size of each chunk in tiles (chunk is square)
const REGION_SIZE: int = 4 # Number of chunks per region side (region is square)
const LOD_RADIUS: int = 4 # How many regions to generate around the player
const REMOVAL_BUFFER: int = 2 # How many regions to keep loaded around the player
const MAX_CHUNK_UPDATES_PER_FRAME: int = 8 # Max number of chunks to build per frame
