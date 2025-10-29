# TODO List

## Next Tasks

- Update the chunk manager to use region checks (when the player changes regions) and hard flush the queues. Only add chunks that don't exist to the queues. Add the optimizations I have annotated in the code comments (thread alive check & a removal queue that processes a set number of chunks per frame or similar. NO pooling for now, just free them). Basically cut all the optimizations and do it bare bones but multi-threaded and functional first. I can add pooling and queue optimizations later.

- Sort the generation queue to build from the player's position first and go outwards.

- Check my code and make private variables start with an underscore: "In essence, a "private variable" in Godot's GDScript is a variable that, by convention, is marked with an underscore to signify that it is for internal use within its defining class and should not be directly interacted with from external code, even though it is technically accessible."

- Update `README.md` and add some basic documentation and at least 1 screenshot - maybe once I have actual terrain working that isn't just simplex noise.

- Re-implement basic editing. (This will require adding some editing functions to the chunk_manager class?)

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
