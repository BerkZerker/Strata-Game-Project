# TODO List

- Split chunk_manager into multiple files for better organization - perhaps one for the main thread & one for the worker thread?

- Add get_tile and set_tile, (possibly the same for chunks & regions) to the chunk_manager for easier access to tiles without needing to get the chunk/region first.

- Clean up the debug overlay code and make it a bit more refined, add some debugging info to the main scene and add proper keybindings to toggle it in the project settings.

- Check my code and make private variables start with an underscore: "In essence, private instance variables should be prefixed with an underscore to indicate that they are intended for internal use only."

- Update `README.md` and add some basic documentation and at least 1 screenshot - maybe once I have actual terrain working that isn't just simplex noise.

---

- Re-implement collision detection for the terrain chunks using swept AABB checking directly against the chunk data rather than using Godot's built-in collision shapes. This will allow for much more precise collision detection and will be necessary for proper terrain editing, as well as better performance.

- Re-implement basic editing. (This will require adding some editing functions to the chunk_manager class?)

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
