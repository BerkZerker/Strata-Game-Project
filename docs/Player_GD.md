# Player.gd Documentation

This script (`Player.gd`) is attached to the `Player` CharacterBody2D in `Player.tscn`. It controls the player's movement, jumping, and jetpack abilities.

## Constants

*   `GRAVITY` (float): The acceleration due to gravity (900.0 units/second^2).
*   `TERMINAL_VELOCITY` (float): The maximum vertical speed the player can reach when falling (700.0 units/second).
*   `HORIZONTAL_LERP` (float): Linear interpolation factor for horizontal movement, controlling how quickly the player accelerates/decelerates horizontally (10.0).
*   `TERMINAL_LERP` (float): Linear interpolation factor for vertical movement when at terminal velocity, controlling how quickly the player reaches terminal velocity (1.5).
*   `MAX_FLOOR_SLOPE` (float): The maximum angle (in radians) of a slope the player can stand on without sliding (1.3 radians, approximately 74.5 degrees).
*   `ACCELERATION` (float): The rate at which the player accelerates horizontally (1200.0 units/second^2).
*   `MAX_SPEED` (float): The maximum horizontal speed the player can reach (300.0 units/second).
*   `JUMP_FORCE` (float): The initial upward velocity applied when the player jumps (-400.0 units/second, negative because Y-axis is down in Godot).
*   `JUMP_GRACE` (float): A small time window (0.2 seconds) after leaving the ground during which the player can still jump.
*   `JETPACK_MAX_FUEL` (float): The maximum amount of jetpack fuel (5.0 seconds).
*   `JETPACK_RECHARGE` (float): The rate at which jetpack fuel recharges when on the ground (1.5 units/second).
*   `JETPACK_FORCE` (float): The upward force applied by the jetpack (-500.0 units/second^2).

## Member Variables

*   `last_ground_touch` (float): Tracks the time since the player last touched the ground. Initialized to `INF` (infinity).
*   `jetpack_fuel` (float): Current amount of jetpack fuel. Initialized to `JETPACK_MAX_FUEL`.

## Functions

### `_physics_process(delta: float)`

Called every physics frame (fixed timestep). This is where all movement and physics calculations should occur.

*   **Horizontal Movement:**
    *   Checks for "move_right" and "move_left" input actions.
    *   Applies `ACCELERATION` to `velocity.x` based on input.
    *   If no horizontal input, `lerp` (linearly interpolates) `velocity.x` towards 0, creating a smooth stop.
    *   Clamps `velocity.x` between `-MAX_SPEED` and `MAX_SPEED`.

*   **Vertical Movement (Gravity & Terminal Velocity):**
    *   If `velocity.y` is less than `TERMINAL_VELOCITY`, applies `GRAVITY` to `velocity.y`, clamping it at `TERMINAL_VELOCITY`.
    *   If `velocity.y` is already at or above `TERMINAL_VELOCITY`, `lerp`s `velocity.y` towards `TERMINAL_VELOCITY`, ensuring a smooth descent at terminal velocity.

*   **Ground Detection & Jetpack Fuel:**
    *   If `is_on_floor()` is true, resets `last_ground_touch` to 0.0 and recharges `jetpack_fuel` up to `JETPACK_MAX_FUEL`.
    *   Otherwise, increments `last_ground_touch` by `delta`.

*   **Jumping & Jetpack:**
    *   If "jump" action is just pressed AND `last_ground_touch` is within `JUMP_GRACE`, applies `JUMP_FORCE` to `velocity.y`. This allows for coyote time (jumping slightly after walking off a ledge).
    *   Else if "jump" action is pressed AND `jetpack_fuel` is greater than 0, applies `JETPACK_FORCE` to `velocity.y` and consumes `jetpack_fuel`.

*   **CharacterBody2D Movement:**
    *   `set_velocity(velocity)`: Sets the calculated velocity for the `CharacterBody2D`.
    *   `set_up_direction(Vector2.UP)`: Sets the "up" direction for floor detection (standard top-down).
    *   `set_max_slides(4)`: Allows the character to slide up to 4 times when encountering obstacles, preventing getting stuck.
    *   `set_floor_stop_on_slope_enabled(true)`: Enables stopping on slopes up to `MAX_FLOOR_SLOPE`.
    *   `set_floor_max_angle(MAX_FLOOR_SLOPE)`: Sets the maximum angle of a slope the player can stand on.
    *   `move_and_slide()`: Moves the character based on its velocity, handling collisions and sliding.
    *   `velocity.y = velocity.y`: This line appears to be a placeholder or a remnant and doesn't have a functional effect. It might have been intended for debugging or a previous feature.

## Extending and Maintaining

*   **New Movement Abilities:** To add new movement abilities (e.g., dash, wall jump), you would add new input checks and modify the `velocity` vector accordingly within `_physics_process`.
*   **Adjusting Physics:** Experiment with the constant values (GRAVITY, ACCELERATION, JUMP_FORCE, etc.) to fine-tune the player's feel and responsiveness.
*   **Animations:** Integrate animation logic based on `velocity` and `is_on_floor()` status.
*   **Health/Damage:** Add variables and functions to manage player health, taking damage, and dying.
*   **Interactions:** Implement logic for the player to interact with other objects in the world (e.g., picking up items, triggering events).
*   **Input Mapping:** Remember to define the "move_right", "move_left", and "jump" input actions in your Godot project settings (Project -> Project Settings -> Input Map).
