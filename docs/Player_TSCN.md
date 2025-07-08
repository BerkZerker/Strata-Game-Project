# Player.tscn Documentation

This scene (`Player.tscn`) defines the player character in the game. It's a reusable scene that can be instantiated in other scenes, such as the `World.tscn`.

## Scene Structure

*   **Player (CharacterBody2D)**
    *   This is the root node of the player scene.
    *   `CharacterBody2D` is a specialized physics body for 2D characters that handles collision detection and response.
    *   It has the `Player.gd` script attached to it, which contains all the movement and interaction logic for the player.
    *   **Script:** `res://scripts/Player.gd`

*   **CollisionShape2D (CollisionShape2D)**
    *   This is a child node of `Player`.
    *   It defines the collision shape for the `CharacterBody2D`.
    *   **Shape:** `RectangleShape2D` with `extents = Vector2(14, 25)`. This creates a rectangular collision box for the player.

## Extending and Maintaining

*   **Visuals:** To add a visual representation for the player (e.g., a sprite, animated sprite), add a `Sprite2D` or `AnimatedSprite2D` node as a child of the `Player` node. Make sure to adjust its position relative to the `CollisionShape2D` so that the visuals align with the collision.
*   **Collision Shape:** If you change the player's visual size or design, you might need to adjust the `extents` of the `RectangleShape2D` in the `CollisionShape2D` node to accurately match the player's new dimensions.
*   **Additional Components:** You can add other nodes as children to the `Player` node to extend its functionality, such as:
    *   `Camera2D` for a player-following camera.
    *   `RayCast2D` for ground detection or checking for interactable objects.
    *   `Area2D` for detecting overlaps with items or hazards.
*   **Script Modifications:** All the core behavior of the player is handled in `Player.gd`. Refer to the `Player.gd` documentation for details on how to modify movement, jumping, and jetpack.
