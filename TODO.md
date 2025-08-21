# TODO List

## Tasks

- Finish cleanup of code and project structure and write up some documentation to at least explain the project structure!

- Add multi-threading support for terrain generation and chunk loading. Note that each new chunk will need to be fully added to the scene in the thread, so the full chunk creation pipeline must be followed from generation of the data, to assigning the chunk data and position, and then adding it to the tree.

  - What I'll likely do is create a chunk_manager scene that is a child of the world scene and actually holds all of the chunk instances. This will be able to fully set up a new chunk and add it to the tree in a thread and can be in charge of loading and unloading chunks as needed.

- Update the terrain generation process to use voronoi diagrams, Lloyd's relaxation, and noise to make patterns in the terrain and update the shader code to render boarders between these patterns.

- Implement a flood fill algorithm for terrain modification based on the voronoi diagram terrain data. Start with breaking.

## Architecture Notes

- Move relavant code from shader_stuff.gd into chunk.gd and figure out a way to load the textures. I'll want to load them based on the block types in the terrain data.
- Note that build is called before the \_ready() function. So we can set up and assign all the data in build, but none of the actual "building" should be done until \_ready() is called. Rename functions to describe accurately.

## Remainging cleanup

- Chunk scene and script & shader_stuff.gd
- World scene and script
- Player scene and script

- Note! Test the `setup_collision_shapes` function with a spare `CharacterBody2D` to make sure my activation code works.
- Note 2! Why is greedy meshing not working correctly? Try removing the extra terrain data.

So I need to load all of the textures in, and assign them to the shader. This is reguardless of the block types in the terrain data. Then apply this shader to the mesh instance in the chunk.
