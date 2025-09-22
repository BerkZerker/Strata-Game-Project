# TODO List

## Current Working Files

- N/A

## Next Tasks

- Restructure the game instance scene tree and add a game_instance.gd script to grab references to the player, chunk manager, and in the future other managers (UI, audio, entities, etc). This will make it easier to access these nodes from other scripts. Then just pass a reference (or use get_parent()?) to access the GameInstance scene in the player and chunk manager scripts as needed.

- Add my own physics check directly against the voxel data for the player instead of using Godot's built-in physics. This will allow for more precise control and avoid issues with fast movement through thin objects. I'll need to first restrucutre the scene tree, and then write a function in the chunk_manager.gd script to get chunk data at a given world position. I'll also need to handle clipping through terrain, perhaps with a raymarch through the traversed voxels in the previous frame.

- Optimize chunk management and add multithreading for chunk updates. Re-implement basic editing functions. Debug chunk loading and unloading.

- Re-implement TILE_SIZE and update all relavant code - note the shader especally will be difficult.

- Fix the stupid player.gd file and write my own collision logic or look for alternative solutions. This should handle gravity, velocity, jumping, collisions, step up on tiles, and coyote jump. I need to figure out how to handle input.

- Check my code and make private variables start with an underscore.

- Update `README.md` and add some basic documentation and at least 1 screenshot.

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
