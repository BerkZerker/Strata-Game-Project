# TODO List

- Add chunk_manager scene and add it to the world. It handles the threaded loading and unloading of chunks. This file will also be in charge of generating the chunk data. This may mean I should make the generator a static function.

- World scene and script cleanup

- Create an input manager node perhaps?

- Player scene and script; go ahead and add a raycast or something and make the collision shape a rect. Do my own slope handling logic. Move the input code for editing the terrain from the world script

- Update `README.md` and add some basic documentation and at least 1 screenshot

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.

  Note! Test the `setup_collision_shapes` function with debugging print statements after editing is added back in to make sure that it works as intended.
