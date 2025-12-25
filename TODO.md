# TODO

- Check over folders: world>chunks, gui, globals, game, entities.

- Check over and clean up the chunk editing code and make sure everything functions correctly and efficiently when modifying terrain, especially with large edits - check for lag spikes.

- Figure out a solution to the reference problem, the player and input manager need access to the chunk manager, perhaps a bus node in the game instance? I need to research if there are any already existing solutions. I also need to keep my code clean and well compartmentalized - each file should have a specific purpose and keep the logic internalized, high complexity within files, low complexity between different scripts.

- Clean up the debug overlay code and make it a bit more refined, add some debugging info to the main scene and add proper keybindings to toggle it in the project settings.

- Implement the WorkerThreadPool for generation, editing, loading and saving of chunks to improve performance and reduce lag spikes during gameplay. Pre-instance all chunk scenes and reuse them to reduce instancing overhead.

- Check over all my recent edits with Claude & myself to make sure the AI generated code is up to my standards and refactor as needed before introducing integrated profiling and documentation.

- Update `README.md` and add some basic documentation and at least 1 screenshot - maybe once I have actual terrain working that isn't just simplex noise.

---

- Add proper terrain generation with realistic terrain features - hills, valleys, cliffs, caves, overhangs, etc.

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.

- Build a movement controller for testing terrain interaction - walking, jumping, falling, and colliding with terrain, this will come in handy when adding more entities besides the player and keep the player clean.

- Consider moving to a component-based system when appliciable - so far I'm thinking stuff like entities, terrain generation, and items in the future.
