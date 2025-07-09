# World.gd Documentation

This script (`World.gd`) is attached to the `World` Node2D in `World.tscn`. It is responsible for generating and managing the destructible terrain, handling player input for debugging, and applying explosions to the terrain.

## Exported Variables

*   `height` (int): The height of the world in "squares". Default is 256.
*   `width` (int): The width of the world in "squares". Default is 256.

## Member Variables

*   `CHUNK` (PackedScene): A preloaded reference to the `Chunk.tscn` scene. This is used to instantiate new terrain chunks.
*   `CHUNK_SIZE` (int): Defines the size of each chunk (8x8 squares).
*   `SQUARE_SIZE` (int): Defines the pixel size of each "square" in the terrain (16x16 pixels).
*   `v_chunks` (int): Calculated number of vertical chunks needed based on `height` and `CHUNK_SIZE`.
*   `h_chunks` (int): Calculated number of horizontal chunks needed based on `width` and `CHUNK_SIZE`.
*   `chunks` (Array): A 2D array storing references to all instantiated `Chunk` nodes.
*   `altered_chunks` (Dictionary): Stores references to chunks that have been modified (e.g., by an explosion) and need their meshes updated.

## Functions

### `_ready()`

Called when the node enters the scene tree for the first time.
*   Enables debug collision shapes (`get_tree().debug_collisions_hint = true`).
*   Initializes the random number generator (`randomize()`).
*   Generates the initial world terrain using a random noise seed.

### `_process(delta_time: float)`

Called every frame.
*   Handles debug input:
    *   If "debug_mouse" is pressed, it moves the player to the mouse position (commented out in the provided code, but shows intent). It also demonstrates how to get the rounded square position and how to set a single vertex.
    *   If "debug_mouse2" is pressed, it triggers an explosion at the mouse position, removing terrain.

### `_draw()`

Called when the node needs to be redrawn.
*   Draws a yellow-ish transparent circle at the mouse position with a radius of 50.0, visually representing the explosion radius.
*   Draws a small red circle at the rounded square position of the mouse, indicating the center of the affected square.
*   Contains commented-out code for drawing chunk and square grid lines, useful for debugging the grid system.

### `_get_noise(noise_seed: int) -> Array`

Generates 2D noise data for terrain generation.
*   Uses `FastNoiseLite` to create a noise map.
*   Normalizes the noise values to be between 0.0 and 1.0 (or slightly above 1.0 in some cases due to the clamping).
*   Returns a 2D array of float values representing the terrain density at each "square". Values closer to 1.0 represent solid terrain, and values closer to 0.0 represent air.

### `generate_world(terrain_data: Array)`

Instantiates and initializes the terrain chunks based on the provided `terrain_data`.
*   Resizes the `chunks` array to hold the correct number of vertical and horizontal chunks.
*   Iterates through each chunk position:
    *   Instantiates a new `Chunk` scene.
    *   Sets the chunk's size (`CHUNK_SIZE`, `SQUARE_SIZE`).
    *   Positions the chunk correctly in the world.
    *   Copies the relevant portion of the `terrain_data` into the chunk's `vertices` array.
    *   Adds the chunk as a child to the `Chunks` Node (a child of the `World` node).
*   After all chunks are instantiated and populated with vertex data, it calls `initalize_mesh()` on each chunk to generate their visual and collision meshes.

### `set_vertex(row: int, col: int, value: float, add: bool = false)`

Modifies the density value of a specific vertex in the terrain. This is the core function for destructing or adding terrain.
*   Takes global `row` and `col` coordinates, a `value` to set, and an optional `add` boolean.
*   If `add` is true, the `value` is added to the existing vertex value; otherwise, it overwrites it.
*   Clamps the final vertex value between 0.0 and 1.0.
*   Calculates which chunk and which vertex within that chunk corresponds to the given global coordinates.
*   Updates the vertex value in the appropriate chunk's `vertices` array.
*   Adds the modified chunk to the `altered_chunks` dictionary, marking it for a mesh update.
*   **Important:** Handles updating adjacent chunks' shared vertices to ensure seamless transitions between chunks. If a vertex is on the edge of a chunk, it also updates the corresponding vertex in the neighboring chunk(s).

### `update_chunks()`

Updates the meshes of all chunks that have been marked as `altered_chunks`.
*   Iterates through the `altered_chunks` dictionary.
*   Calls `initalize_mesh()` on each altered chunk to regenerate its visual and collision meshes.
*   Clears the `altered_chunks` dictionary after updating.

### `explosion(location: Vector2, radius: float, intensity: float)`

Applies an explosion effect to the terrain, modifying vertex densities within a circular radius.
*   Converts `radius` and `location` from pixel coordinates to "square" coordinates.
*   Calculates a bounding box around the explosion area.
*   Iterates through each "square" within the bounding box:
    *   Calculates the distance from the current square to the explosion `location`.
    *   Determines the `intensity` of the effect at that square based on its distance from the center (closer squares are more affected).
    *   Calls `set_vertex()` for each square, adding the calculated `intensity` to its current vertex value. A negative `intensity` will remove terrain (destruct), while a positive `intensity` would add terrain.
*   Calls `update_chunks()` to refresh the meshes of all affected chunks.

## Extending and Maintaining

*   **Terrain Generation:** To change the initial terrain shape, modify the `_get_noise` function. You could experiment with different `FastNoiseLite` properties (frequency, noise type, octaves) or even use a different noise generation library.
*   **Destruction/Addition Mechanics:** The `explosion` function is a good example of how to modify the terrain. You can create new functions that use `set_vertex` to implement different terrain manipulation tools (e.g., digging, building, smooth erosion).
*   **Chunk Management:** The `World` script handles the chunk grid and ensures seamless updates. When modifying terrain, always use `set_vertex` to ensure adjacent chunks are updated correctly.
*   **Performance:** For very large worlds or frequent terrain modifications, consider optimizing the `update_chunks` function or implementing a more granular update system (e.g., only updating a small region of a chunk instead of the whole chunk).
*   **New Terrain Types:** If you want different types of terrain (e.g., rock, dirt, water), you would need to extend the `Chunk.gd` script to handle different vertex values representing different materials and modify the mesh generation accordingly. This would likely involve using different colors or textures based on the vertex value.
