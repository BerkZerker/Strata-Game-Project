# TODO List

## Code Cleanup

- The world.gd file needs some cleanup - I need to remove the old collision shapes AFTER adding the new ones otherwise the physics gets janked. The entire terrain updating process (collision and visuals) needs to be worked on.
- I need to clean up the chunk.gd file and possibly remove the mesh2d from the scene, to do it in code. This would allow me to set it up before adding the instance to the parent scene. Additionally I need to pass all the args to a setup function, not have them hardcoded.
- terrain_mesher.gd likely goes hand in hand with chunk.gd and will need some of it's code moved to a new file, and I'll likely have to do some renaming as well (mesher -> builder). Then name the new file mesher and make it responsible for handling the mesh.
- Overall clean up the generation, building, and meshing code for the world, clean up the shader, and honestly maybe then add multi-threading so all of this can be done on a separate thread.
- I need to figure out a way to use the shader to not only draw terrains but also shade the boarders between them and make a better generator to generate clumps in the terrain data.

  NOTE: Most of the "meshing" code in `mesh_chunk.gd` is really building code - I can just make a new file to set up the visuals and move the visuals code into that.

## NormalMap Link

[smartnormal](https://www.smart-page.net/smartnormal/)
