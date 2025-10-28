extends Node

# This is kind of a placeholder. I may move the logic away
# from using signals to a more direct approach later on where I 
# directly call functions from the game instance. For example:
# `player.set_chunk_manager_reference(chunk_manager)` rather than doing
# something signal based. This should help with clarity especially when 
# editing terrain and the like.