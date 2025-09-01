# TODO List

- SignalBus - an autoload singleton with all signals defined inside. This will be what the player and ChunkManager use to comunicate.

- GameInstance - the main game instance - holds the game, the ui, etc.

  - World - the main stage for all in-game objects.

    - ChunkManager - handles the loading and unloading of chunks, as well as the generation of chunk data. For now this will hold it's own variables that determine world generation. Using the player's signal for crossing chunk boundaries, it will load and unload chunks and handle activation and deactivation of the collision shapes.

      - TerrainGenerator - generates the terrain data for each chunk.

  - Player - the main player, inventory, player data, etc. I will emit a signal when the player crosses a chunk boundary which will be used for chunk loading and unloading.

- Fix the stupid player.gd file and write my own collision logic or look for alternative solutions. This should handle gravity, velocity, jumping, collisions, step up on blocks, and coyote jump. I need to figure out how to handle input.

- World scene and script cleanup

  Note! Test the `setup_collision_shapes` function with debugging print statements after editing is added back in to make sure that it works as intended.

- Update `README.md` and add some basic documentation and at least 1 screenshot

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
