# TODO List

## Scene Structure

- GameInstance - the main game instance - holds the game, the ui, etc.

  - World - the main stage for all in-game objects. Just a container for now (Node2D).

    - ChunkManager - handles the loading and unloading of chunks, as well as the generation of chunk data. For now this will hold it's own variables that determine world generation. Using the player's signal for crossing chunk boundaries, it will load and unload chunks and handle activation and deactivation of the collision shapes.

      - TerrainGenerator - generates the terrain data for each chunk.

  - Player - the main player, inventory, player data, etc. I will emit a signal when the player crosses a chunk boundary which will be used for chunk loading and unloading. NOTE - how will the player know when it crosses a chunk boundary?

## Current Working Files

- chunk_manager.gd, chunk.gd - mainly chunk, get it working with the new chunk manager. Then add multithreading for chunk updates.

## Next Tasks

- Get the chunk_manager to load and unload chunks based on the player's position. This will use a signal via the signal_bus.gd when the player crosses a chunk boundary. The chunk manager will then load and unload chunks based on the LOD_RADIUS variable in global_settings.gd. the chunk_manager will also handle activating and deactivating the collision shapes for the chunks based on the player's position, as well as using the terrain_generator to generate the terrain data on the fly for each chunk.

- Re-implement TILE_SIZE and update all relavant code - note the shader especally will be difficult.

- Fix the stupid player.gd file and write my own collision logic or look for alternative solutions. This should handle gravity, velocity, jumping, collisions, step up on tiles, and coyote jump. I need to figure out how to handle input.

- Update `README.md` and add some basic documentation and at least 1 screenshot.

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
