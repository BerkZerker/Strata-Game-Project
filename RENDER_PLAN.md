# Terrain Rendering Plan

This document outlines a plan to refactor the terrain rendering to use a shader-based approach for better performance and flexibility.

## Current System Overview

- `world.gd`: Main script that orchestrates world generation and holds the `chunk_data` array.
- `chunk.gd`: Represents a section of the world, currently holding collision shapes.
- `terrain_generator.gd`: Creates the initial `chunk_data` using noise.
- `terrain_mesher.gd`: Uses `GreedyMeshing.gd` to create `StaticBody2D` collision shapes from the `chunk_data`.

The current system generates collision meshes for the terrain, but does not handle the visual representation.

## Proposed Shader-Based Rendering

The goal is to create a single `MeshInstance2D` per chunk and use a shader to draw the terrain tiles. This will be much more performant than using individual nodes for each tile.

### 1. Texture Atlas

- Create a texture atlas (a single image file) that contains all the possible terrain tiles.
- Each tile in the atlas will correspond to a specific integer value in the `chunk_data` array.
- For example, `0` could be air, `1` could be dirt, `2` could be stone, etc.

### 2. Chunk Geometry

- For each chunk, instead of generating collision shapes, we will generate a single `MeshInstance2D`.
- The mesh will be a simple quad (a rectangle) that covers the entire area of the chunk.

### 3. Vertex Shader

- The vertex shader will be simple and will just pass through the vertex positions of the quad.

### 4. Fragment Shader

The fragment shader will be responsible for drawing the correct tile from the texture atlas onto the correct position on the screen.

- **Uniforms:**

  - `sampler2D tile_atlas`: The texture atlas containing all the terrain tiles.
  - `sampler2D chunk_data_texture`: A texture containing the tile data for the current chunk. This will be generated from the `chunk_data` array.
  - `vec2 chunk_size`: The size of the chunk in tiles (e.g., 64x64).
  - `vec2 tile_size`: The size of a single tile in the atlas in pixels (e.g., 16x16).
  - `vec2 atlas_size`: The size of the entire texture atlas in pixels.

- **Logic:**
  1.  Get the current fragment's coordinates within the chunk (`UV`).
  2.  Calculate the corresponding tile coordinate in the `chunk_data_texture`.
  3.  Sample the `chunk_data_texture` at that coordinate to get the tile type (the integer value).
  4.  Convert the integer tile type to a 2D coordinate that points to the correct tile in the `tile_atlas`.
  5.  Calculate the UV coordinates for the specific tile within the `tile_atlas`.
  6.  Sample the `tile_atlas` with the calculated UVs to get the final color for the fragment.

### 5. Implementation Steps

1.  **Create the Texture Atlas:**

    - Create a `tiles.png` (or similar) file and add a few simple tile variations (e.g., grass, dirt, stone).

2.  **Modify `chunk.gd`:**

    - Remove the `StaticBody2D` and collision shape generation (for now, we can add it back later).
    - Add a `MeshInstance2D` to the `chunk.tscn` scene.
    - In `setup_area_2d`, create a `QuadMesh` and assign it to the `MeshInstance2D`.

3.  **Create the Shader:**

    - Create a new `terrain.gdshader` file.
    - Implement the vertex and fragment shaders as described above.

4.  **Modify `terrain_mesher.gd`:**

    - In `mesh_chunk`, instead of creating collision shapes, it should:
      1.  Create a new `Image` from the `chunk_data` array.
      2.  Create an `ImageTexture` from the `Image`.
      3.  Get the `MeshInstance2D` from the `chunk` instance.
      4.  Set the `chunk_data_texture` uniform on the shader material with the newly created texture.

5.  **Update `world.gd`:**
    - The main loop in `_ready` will remain mostly the same, but it will now be adding chunks with `MeshInstance2D`s instead of `StaticBody2D`s.

## Benefits

- **Performance:** Drawing a single mesh per chunk is significantly faster than having many individual nodes.
- **Flexibility:** It will be easy to add new tile types by simply adding them to the texture atlas and the `chunk_data`.
- **Advanced Effects:** This shader-based approach opens the door for more advanced visual effects, such as smooth tile transitions, animations, and lighting effects.
