# TODO List

## Current Working Files

- N/A

## Next Tasks

- Optimize chunk loading and unloading to use regions > chunks > cells. Do generation region by region, and generate a region of chunks at a time. This will let the worker thread actually have something to do and should optimize performance when moving quickly through the world. Use the `global_settings.gd` constants for the settings. Also in the `chunk_manager.gd`, update the generation so that only the new terrain gen is done in a seperate thread, and the rest is done in the main thread. Remove the object pooling and reuse - a chunk should be deleted when it's out of range and a new chunk created when needed. Also optimze for movement in the world (chunks shouldn't be generated twice if the player moves back and forth quickly, and chunks should be removed from the generation queue if the player moves away from them before they are generated).

- Check my code and make private variables start with an underscore.

- Update `README.md` and add some basic documentation and at least 1 screenshot - maybe once I have actual terrain working that isn't just simplex noise.

- Re-implement basic editing.

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
