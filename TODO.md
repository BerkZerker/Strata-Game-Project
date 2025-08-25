# TODO List

- Fix the stupid player.gd file and write my own collision logic. This should handle gravity, velocity, jumping, collisions, step up on blocks, and coyote jump.

- Create an input manager node as part of the game scene. This should be able to talk to the player and world scenes.

- Add chunk_manager scene and add it to the world. It handles the threaded loading and unloading of chunks. This file will also be in charge of generating the chunk data. This may mean I should make the generator a static function.

- World scene and script cleanup

  Note! Test the `setup_collision_shapes` function with debugging print statements after editing is added back in to make sure that it works as intended.

- Update `README.md` and add some basic documentation and at least 1 screenshot

- Research algorithms to generate tessellating shapes as cells in the terrain using data driver attributes such as roughness, scale variance, and starting shape. Maybe voronoi diagrams & Lloyd's relaxation?

- Implement a flood fill algorithm for terrain modification based on the cell terrain data. Start with breaking.
