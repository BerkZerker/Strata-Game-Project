# TODO List

## Tasks

- Finish cleanup of code and project structure and write up some documentation to at least explain the project structure!

- Add multi-threading support for terrain generation and chunk loading.

- Update the terrain generation process to use voronoi diagrams and noise to make patterns in the terrain and update the shader code to render boarders between these patterns.

- Implement a flood fill algorithm for terrain modification based on the voronoi diagram terrain data. Start with breaking.

## Architecture Notes

- Move relavant code from shader_stuff.gd into chunk.gd and figure out a way to load the textures. I'll want to load them based on the block types in the terrain data.

## Remainging cleanup

- Player scene and script
- World scene and script
- Chunk scene and script & shader_stuff.gd
- Note! Test the `setup_collision_shapes` function with a spare `CharacterBody2D` to make sure my activation code works.
