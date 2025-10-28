# TODO List

## Current Working Files

- N/A

## Next Tasks

- Optimize chunk loading and unloading to use regions > chunks > cells. Do generation region by region, and generate a region of chunks at a time. This will let the worker thread actually have something to do and hopefully clean up some queue issues. Also clean up the queues.

- Check my code and make private variables start with an underscore.

- Update `README.md` and add some basic documentation and at least 1 screenshot - maybe once I have actual terrain working that isn't just simplex noise.

- Re-implement basic editing.

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
