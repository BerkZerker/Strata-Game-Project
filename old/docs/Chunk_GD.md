# Chunk.gd Documentation

This script (`Chunk.gd`) is attached to the `Chunk` Node2D in `Chunk.tscn`. It is responsible for generating the visual mesh and collision shapes for a single chunk of destructible terrain based on a 2D array of vertex density values. It uses the Marching Squares algorithm to achieve this.

## Constants

*   `CONSTANT_LOOKUP` (Array): A lookup table for constant vertices within a square. Each sub-array corresponds to a 4-bit case (0-15) representing the configuration of solid corners in a square. The values are `Vector2` coordinates relative to the top-left corner of a square (0,0).
    *   `0b0001` (1): Top-left corner is solid.
    *   `0b0010` (2): Top-right corner is solid.
    *   `0b0100` (4): Bottom-right corner is solid.
    *   `0b1000` (8): Bottom-left corner is solid.
    *   Combinations of these bits represent different solid corner configurations.
*   `TRIANGLE_LOOKUP` (Array): A lookup table defining how to form triangles for the visual mesh based on the 4-bit case.
    *   Positive numbers refer to midpoints (0: top, 1: right, 2: bottom, 3: left).
    *   Negative numbers refer to constant vertices from `CONSTANT_LOOKUP` (e.g., -1 refers to the first constant vertex for that case).
    *   Each sub-array contains indices that form triangles (3 indices per triangle).
*   `CONTOUR_LOOKUP` (Array): A lookup table for following contours to generate collision shapes.
    *   Each sub-array defines the "in" and "out" directions for traversing the contour based on the 4-bit case.
    *   Directions are 0: Up, 1: Right, 2: Down, 3: Left.
    *   Special cases (0b0101 and 0b1010) have specific handling for ambiguous contours.
*   `SURFACE_THRESHOLD` (float): The density value (inclusive) above which a vertex is considered "solid" (0.5).
*   `MIN_MASS_AREA` (float): Unused coefficient for `square_size`.
*   `NO_MASS` (int): A special value (255) used to indicate that a square has no associated mass ID.
*   `CASE_MASK` (int): A bitmask (0b00001111) to extract the 4-bit case from `contour_flags`.
*   `VALID_MASK` (int): A bitmask (0b00010000) indicating if a square has a valid contour (i.e., not fully solid or fully empty).
*   `VISITED_MASK` (int): A bitmask (0b00100000) indicating if a square has been visited during contour following.
*   `SPECIAL_MASK` (int): A bitmask (0b01000000) indicating a special ambiguous case (0b0101 or 0b1010) in Marching Squares.

## Member Variables

*   `chunk_size` (int): The number of squares along one dimension of the chunk (e.g., 8 for an 8x8 chunk).
*   `square_size` (int): The pixel size of each individual square.
*   `vertices` (Array): A 2D array of floats representing the density of each vertex in the chunk. Values typically range from 0.0 (empty) to 1.0 (solid).
*   `empty_chunk` (bool): A flag indicating if the chunk is completely empty (no solid terrain).

## Functions

### `_ready()`

Called when the node enters the scene tree for the first time. Currently, it does nothing.

### `set_size(chunk_size: int, square_size: int)`

Initializes the chunk's dimensions and resizes the `vertices` array.
*   Sets `self.chunk_size` and `self.square_size`.
*   Resizes the `vertices` array to `(chunk_size + 1) x (chunk_size + 1)` to accommodate all vertex points for the squares within the chunk.

### `initalize_mesh()`

This is the core function that generates both the visual mesh and the collision shapes for the chunk. It implements the Marching Squares algorithm.

1.  **Initialization:**
    *   `square_count`: Total number of squares in the chunk.
    *   `contour_flags`: `PackedByteArray` to store flags for each square (case, valid, visited, special).
    *   `contour_mass_id`: `PackedByteArray` to store the mass ID for each square during contour following.
    *   `contour_midpoints`: Dictionary to store the calculated midpoints for each square's contour.
    *   `mesh_vertices`: `PackedVector2Array` to store the vertices for the visual mesh.
    *   `mesh_colors`: `PackedColorArray` to store colors for the visual mesh (currently all white).

2.  **Marching Squares (Visual Mesh Generation):**
    *   Iterates through each square in the chunk.
    *   **Calculate Midpoints:** For each square, it calculates 4 midpoints along its edges based on the `SURFACE_THRESHOLD` and the density values of its corners. These midpoints are where the contour lines will pass.
    *   **Determine Case:** It determines the 4-bit `case` for the current square based on which of its four corners have a density value greater than or equal to `SURFACE_THRESHOLD`.
    *   **Store Contour Flags:** Sets `contour_flags[idx]` with the calculated `case` and additional masks (`VALID_MASK`, `SPECIAL_MASK`) if applicable. It also stores the relevant midpoints in `contour_midpoints`.
    *   **Generate Triangles:** Uses the `TRIANGLE_LOOKUP` table to determine which vertices (midpoints or constant corners) form the triangles for the visual mesh for the current `case`. These vertices are added to `mesh_vertices` and `mesh_colors`.

3.  **MeshInstance2D Update:**
    *   Frees any existing collision shapes from `$StaticBody2D`.
    *   If `mesh_vertices` is empty (meaning no solid terrain in the chunk), it hides the `$MeshInstance2D`.
    *   Otherwise, it creates a new `ArrayMesh` from `mesh_vertices` and `mesh_colors` (using `Mesh.PRIMITIVE_TRIANGLES`) and assigns it to `$MeshInstance2D.mesh`, then shows the mesh.

4.  **Collision Shape Generation (Contour Following):**
    *   `masses`: An array to store arrays of `Vector2` points, each representing a closed contour (a "mass" of terrain).
    *   `has_followed_edge`: A flag to track if any contour has been followed along the chunk's outer edge.
    *   **Contour Traversal:**
        *   Iterates through each square in the chunk.
        *   If a square has a `VALID_MASK` and hasn't been `VISITED_MASK`, it starts following a contour:
            *   It traverses the contour by moving from square to square, adding midpoints to the current `mass` array.
            *   It uses `CONTOUR_LOOKUP` to determine the next direction to move.
            *   Handles `SPECIAL_MASK` cases for ambiguous contours.
            *   Marks visited squares with `VISITED_MASK` and assigns them a `contour_mass_id`.
            *   Includes logic to handle contours that reach the chunk boundaries, effectively "wrapping" them to the other side of the chunk or closing them off at the edge.
    *   **Edge Case (Fully Solid Chunk):** If no contours were followed but the top-left vertex is solid, it assumes the entire chunk is solid and creates a rectangular collision shape covering the whole chunk.
    *   **Empty Chunk Check:** Sets `empty_chunk` to `true` if no masses were found.

5.  **CollisionPolygon2D Creation:**
    *   `connections`: An array to store connections between different `mass` contours (used for combining adjacent contours).
    *   **Connecting Contours:** This section attempts to identify and combine adjacent contours that should form a single collision shape. It uses a breadth-first search-like approach to find connected squares and merge their associated `mass` arrays. This is a complex part of the algorithm designed to create larger, more efficient collision polygons.
    *   **Creating Collision Shapes:** Iterates through the `masses` array. For each valid (not combined) `mass`, it creates a new `CollisionPolygon2D` node, sets its `polygon` property to the `PackedVector2Array` of the `mass` points, and adds it as a child to the `$StaticBody2D` node.

## Extending and Maintaining

*   **Marching Squares Logic:** The `CONSTANT_LOOKUP`, `TRIANGLE_LOOKUP`, and `CONTOUR_LOOKUP` tables are fundamental to the Marching Squares algorithm. Modifying these would drastically change how the terrain is rendered and collides.
*   **Surface Threshold:** Adjusting `SURFACE_THRESHOLD` will change what density value is considered "solid" terrain, affecting the shape of the generated contours.
*   **Visuals:**
    *   To change the terrain's appearance, modify the `mesh_colors.append(Color.WHITE)` line in `initalize_mesh()` to use different colors or even textures based on the vertex density or other properties.
    *   You could also add a `ShaderMaterial` to the `MeshInstance2D` for more advanced visual effects.
*   **Collision Optimization:** The collision generation logic is complex. For very large or highly detailed chunks, you might explore further optimizations for generating collision shapes, such as simplifying polygons or using a different collision generation approach if performance becomes an issue.
*   **Multi-material Terrain:** To support different terrain materials (e.g., rock, dirt), you would need to store additional data per vertex (e.g., a material ID) and modify `initalize_mesh()` to generate different visual elements (e.g., separate meshes, different textures) based on these material IDs.
*   **Debugging:** Understanding the `case` values and the `contour_flags` can be helpful for debugging issues with mesh or collision generation. You could add debug drawing to visualize these values.
