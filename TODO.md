# TODO List

## Chunk Generation & Editing

- Add functions for editing terrain, but handle borders between chunks. Figure out a data-type (2d array?) to determine the shape of the edit.
- Through the world instance. Then the world indexes the chunks required, and sends the edits to them, and they update their data. Then we add them to a list of "dirty" chunks, so they can have their meshes and eventually textures updated.

## Texturing

- Learn shaders
