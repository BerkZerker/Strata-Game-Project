# TODO

- Re-implement basic editing, using the new chunk data access methods. I should be able to the mouse and left click to edit terrain, with a simple gui to show different terrain types (air, dirt, stone, grass, etc) and a simple circle and square brushes to choose from. There should be a brush preview as well, showing where the brush will affect the terrain. The brush size can be adjusted with the + and - keys. This should use the GUI_manager node in the main scene to start building the GUI. - DONE?

- Clean up the debug overlay code and make it a bit more refined, add some debugging info to the main scene and add proper keybindings to toggle it in the project settings.

- Check over all my recent edits with Claude & myself to make sure the AI generated code is up to my standards and refactor as needed before introducing integrated profiling and documentation.

- Build my own profiler to replace the Godot built-in one, so I can get more detailed information about performance and memory usage for each funciton and integrate it with the debug overlay.

- Update `README.md` and add some basic documentation and at least 1 screenshot - maybe once I have actual terrain working that isn't just simplex noise.

---

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

  - Generate a random set of points based off of a seed within the terrain and use these to fracture the terrain as needed into cells. This does raise an important consideration - while this technique could be used for braking objects such as stones or bricks, what about not-cellular materials such as dirt, sand, and gravel? These wouldn't be cellular materials and would require a different approach to fracturing. I'll need to further explore how to handle this as this is the main challenge of non-blocky voxel terrain.

    Note that I will need a dictionary to track which cell numbers have been used for all material types that fracture into cells.

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.

- Build a movement controller for testing terrain interaction - walking, jumping, falling, and colliding with terrain, this will come in handy when adding more entities besides the player and keep the player clean.

- Consider moving to a component-based system when appliciable - so far I'm thinking stuff like entities, terrain generation, and items in the future.
