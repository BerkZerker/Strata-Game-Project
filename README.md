# Strata-Game-Project

2d Voxel Based Space Game

Functionality of terrain:

- random generation
- editable
- chunk based with loadable and unloadable chunks

# NOTE

## ToDo

- Read over gemini code and approve in `marching_squares.gd`
- Figure out how to correctly pad data so that the marching squares algorithm generates correctly.

All data will be stored in the 2d array representing the world.
This is the ground truth for not only the collision polygons, but also the textures,
the edits to the terrain, the physics, the sound effects, basically everything.

The ONLY thing that the marching squares algorithm does is bake everything into a nice smooth mesh - it's really just
a fancier way of rendering "voxel" terrain.
