# project-next — Architecture Documentation

> Action-Adventure Zelda-like game built in **Godot 4.7** (GDScript, GL Compatibility renderer).
> This document was generated from a full analysis of the `lantern-elf/project-next` repository source code.

---

## 1. Project Overview

| Item | Value |
|---|---|
| Project name | `project-next` |
| Description (project.godot) | "Action Adventure Zelda-like game" |
| Engine | Godot 4.7, `gl_compatibility` renderer |
| Language | GDScript, GDShader |
| Viewport resolution | 640×360, stretch mode `canvas_items` |
| Window | Borderless |
| Main scene | `Scenes/area_test.tscn` |

This project is a classic Zelda-style top-down 2D game: the player moves in 4 directions, attacks with a sword, can dash, has health, and interacts with enemies/dummies and hazards (spikes). The architecture relies on two main patterns: the **Component Pattern** and a **Finite State Machine (FSM)**, plus one **Autoload Singleton** that globally gates the player's actions.

---

## 2. Key Project Settings

**Autoload (Singleton)**
```
PlayerActionManager → res://Scripts/Managers/PlayerActionManager.gd
```
Accessed globally by the name `PlayerActionManager` from any script without needing an explicit reference.

**Input Map (custom actions, beyond the built-in `ui_*`)**
| Action | Keyboard | Gamepad |
|---|---|---|
| `attack` | X | Joypad button 2 |
| `dash` | Shift (physical keycode 4194326) | Joypad button 0 |

Movement (`ui_left/right/up/down`) uses Godot's built-in input actions.

**Physics Layers**
```
Layer 1 = "Player"
Layer 2 = "Props"
```

**Global Groups**
```
Hitable, Player
```
Used to filter which nodes can receive damage and to distinguish the player's hitbox from enemy hitboxes.

**Rendering**: `gl_compatibility` (both desktop and mobile) — a common choice for 2D pixel art to keep the game compatible across many devices.

---

## 3. Folder Structure

```
project-next/
├── project.godot
├── icon.svg / icon.png
├── sssss.gdshader              # "echo/scrolling" effect shader (see §9)
├── Assets/
│   ├── Characters/Player/      # player spritesheet
│   ├── Entity/                 # dummy/enemy spritesheet
│   ├── Tilesets/                # tileset + tile_set.tres
│   └── UIs/                    # UI button assets
├── Scenes/
│   ├── area_test.tscn          # ⭐ MAIN SCENE — test level with tilemap
│   ├── propechy.tscn           # showcase scene for the "sssss" shader
│   ├── Character/
│   │   ├── player.tscn         # player scene
│   │   └── dummy.tscn          # basic training dummy/enemy target
│   ├── Obstacles/
│   │   └── spikes.tscn         # hazard area
│   └── UI/
│       └── button.tscn         # generic UI button
├── Scripts/
│   ├── Components/             # reusable components (composition pattern)
│   │   ├── animation_player.gd
│   │   ├── damage_component.gd
│   │   ├── heatlh_component.gd     # (typo: "heatlh" instead of "health")
│   │   ├── hitbox_component.gd
│   │   ├── state.gd
│   │   ├── state_mechine.gd        # (typo: "mechine" instead of "machine")
│   │   ├── velocity_component.gd
│   │   ├── dummy/
│   │   │   └── dummy_velocity.gd
│   │   └── player/
│   │       ├── input_component.gd
│   │       ├── player.gd
│   │       ├── player_attack.gd    # State: Attack
│   │       ├── player_dash.gd      # State: Dash
│   │       ├── player_idle.gd      # State: Idle
│   │       ├── player_move.gd      # State: Move
│   │       └── player_velocity.gd
│   ├── Entity/Dummy/
│   │   └── dummy.gd
│   ├── Managers/
│   │   └── PlayerActionManager.gd  # Autoload
│   └── Tiles/
│       └── hazard_area.gd
├── Shaders/
│   └── flash_hit.gdshader      # "on hit" effect (white flash)
└── addons/
    └── discord-rpc-gd/          # third-party addon — Discord Rich Presence
```

---

## 4. Architecture Patterns

### 4.1 Component Pattern
Every entity (`Player`, `Dummy`) is a `CharacterBody2D` that does **not** hold all its logic in one script. Instead, logic is split into child nodes, each with a single responsibility, wired together via `@export` NodePaths in the editor:

```
CharacterBody2D  (e.g. Player / Dummy)
 ├── HealthComponent      → HP, damage, heal, flash-hit
 ├── HitboxComponent       → Area2D that receives attacks
 ├── VelocityComponent     → movement & direction (base class)
 ├── InputComponent        → (Player only) reads input
 └── StateMachine           → (Player only) FSM state
```

The benefit of this pattern: `Dummy` and `Player` can share an identical `HealthComponent` and `HitboxComponent`, while `VelocityComponent` is *extended* differently (`player_velocity.gd` vs `dummy_velocity.gd`) to fit each entity's needs.

### 4.2 Finite State Machine (FSM)
For the Player specifically, movement/animation is driven by a generic FSM (`state_mechine.gd` + `state.gd`) whose concrete states are child nodes of type `State`:

```
StateMachine
 ├── Idle    (player_idle.gd)
 ├── Move    (player_move.gd)
 ├── Attack  (player_attack.gd)
 └── Dash    (player_dash.gd)
```

Transitions happen via the `Transitioned(state, new_state_name)` signal, emitted by the active state and caught by `StateMachine.on_child_transition()`, which looks up the new state in the `states` dictionary (keyed by lowercase node name) and calls `exit()` on the old state followed by `enter()` on the new one.

### 4.3 Autoload Singleton — Global Action Lock
`PlayerActionManager` is the project's only singleton. It acts as a **cooldown/lock gate** so attack & dash inputs can't be spammed faster than their animations allow, and it stores `attack_state` (the 1–4 combo counter) across frames without needing to persist it inside the Attack state itself (since states are re-entered/exited every time an attack happens).

---

## 5. Class & Script Reference

### 5.1 `Scripts/Components/state.gd`
```gdscript
class_name State extends Node
```
Abstract base class for all FSM states.

| Export var | Type | Description |
|---|---|---|
| `body` | CharacterBody2D | reference to the owning entity |
| `state_machine` | StateMachine | reference to the parent FSM |
| `animation_player` | AnimationPlayer | for triggering animations |
| `velocity_component` | VelocityComponent | for movement |
| `input` | InputComponent | optional, only set if the state needs input |

| Signal | Description |
|---|---|
| `Transitioned(state, new_state_name)` | Emitted to request a state change |

| Method (virtual, overridden in subclasses) | Called from |
|---|---|
| `enter()` | `StateMachine` when the state becomes active |
| `update(delta)` | `StateMachine._process()` every frame |
| `physics_update(delta)` | `StateMachine._physics_process()` every physics tick |
| `exit()` | `StateMachine` when the state is left |

### 5.2 `Scripts/Components/state_mechine.gd`
```gdscript
class_name StateMachine extends Node
```
| Export var | Description |
|---|---|
| `initial_state: State` | the first state on `_ready()` |
| `current_state: State` | the currently active state |

| Method | Description |
|---|---|
| `_ready()` | Collects all child nodes of type `State` into the `states` dictionary (key = `name.to_lower()`), connects each one's `Transitioned` signal to `on_child_transition`, then calls `initial_state.enter()` |
| `_process(delta)` | Forwards to `current_state.update(delta)` |
| `_physics_process(delta)` | Forwards to `current_state.physics_update(delta)` |
| `on_child_transition(state, new_state_name)` | Transition handler: ignores the call if `state` isn't `current_state` (prevents a stale state from causing a race condition); looks up the new state in the dictionary; calls `exit()` on the old one → `enter()` on the new one |

**Design note**: because the lookup uses `to_lower()` on the node name, the node names in the scene tree (`Idle`, `Move`, `Attack`, `Dash`) **must match** the strings emitted in `Transitioned.emit(self, "Attack")` etc. (case-insensitive, but spelling must be exact).

### 5.3 `Scripts/Components/velocity_component.gd`
```gdscript
class_name VelocityComponent extends Node
```
Base class for movement & sprite-direction resolution (used by both Player and Dummy, each via its own subclass).

| Export var | Default | Description |
|---|---|---|
| `speed` | 100.0 | base movement speed |
| `body` | — | the owning CharacterBody2D |

| Internal var | Description |
|---|---|
| `current_direction` / `last_direction` | string: `"down" \| "up" \| "left" \| "right"` — used to pick the animation name |

| Method | Description |
|---|---|
| `get_direction_name(input_vector, previous_direction)` | Converts a `Vector2` input into a direction string, preferring to keep the previous direction when it's still valid, falling back to priority order `down > up > left > right` |
| `get_direction_vector()` | The inverse of the above — direction string → `Vector2` (`down/up/left/right`) |
| `knockback(power, origin)` | Pushes the body away from `origin` by `power`, then stops after 0.1s |
| `stop_move()` | `velocity = Vector2.ZERO` |

⚠️ **Minor quirk**: in `get_direction_vector()`, the line `print(directions_mapping)` is placed **after** the `return`, so it never executes (already flagged with `@warning_ignore("unreachable_code")` by the author — appears to be intentionally left-over debug code).

### 5.4 `Scripts/Components/player/player_velocity.gd`
```gdscript
extends VelocityComponent
```
| Export var | Description |
|---|---|
| `input_component: InputComponent` | source of directional input |

| Method | Description |
|---|---|
| `_physics_process(delta)` | Updates `current_direction` from input, then calls `body.move_and_slide()` |
| `move(direction, _speed=speed)` | Sets velocity directly to direction × speed (used by the **Move** state) |
| `attack_move(direction)` | A burst of velocity at 3× speed in the input direction (or 0.5× speed in the last-faced direction if there's no input), auto-resets to 0 after 0.1s — gives a small "lunge" while attacking |
| `dash(direction)` | A burst of velocity at 5× speed, auto-resets after 0.1s — used by the **Dash** state |

### 5.5 `Scripts/Components/dummy/dummy_velocity.gd`
```gdscript
extends VelocityComponent
```
A minimal version for `Dummy`: `_physics_process()` only calls `body.move_and_slide()` with no input logic (since the Dummy is static / not player-controlled). `_ready()` is still an empty placeholder.

### 5.6 `Scripts/Components/player/input_component.gd`
```gdscript
class_name InputComponent extends Node
```
| Signal | Description |
|---|---|
| `direction_changes` | Emitted whenever the input direction changes |

| Var | Description |
|---|---|
| `last_direction`, `direction_changed` | direction-change tracking |
| `attack_disabled` | manual lock flag (currently never set to true — the related `start_attack_cooldown` function is commented out) |

| Method | Description |
|---|---|
| `get_input_direction()` | `Input.get_vector("ui_left","ui_right","ui_up","ui_down")` |
| `attack()` | `true` if the `attack` button was just pressed **and** `attack_disabled == false` |
| `dash()` | `true` if the `dash` button was just pressed |

### 5.7 `Scripts/Components/player/player.gd`
```gdscript
extends CharacterBody2D
```
The main script on the Player's root node. It is **not** part of the FSM itself — it's the "glue" between `InputComponent`, `PlayerActionManager`, and `StateMachine`.

| Export var | Description |
|---|---|
| `velocity_component`, `health_component`, `hitbox_component`, `state_machine`, `animation_player`, `input_component` | wiring to all child components |

| Method | Description |
|---|---|
| `_process(delta)` | Core per-frame logic: |

`_process()` flow:
1. If the attack button is pressed **and** `PlayerActionManager.can_attack`: lock attacks for 0.3s (`lock_attack`), then force the FSM into the **Attack** state via `Transitioned.emit(current_state, "Attack")` — note this is emitted directly from `player.gd`, not from the state itself.
2. If the attack button is **not** pressed: accumulate `no_attack_time`; after 1 second of no attacking, call `PlayerActionManager.reset_attack_state()` (resets the combo counter to 0).
3. If the dash button is pressed **and** `can_dash`: lock dash for 0.5s, force a transition to **Dash**.

### 5.8 Player States

**`player_idle.gd`**
- `enter()`: no-op
- `update(delta)`: plays the `idle_<direction>` animation
- `physics_update(delta)`: if there is directional input → transitions to **Move**

**`player_move.gd`**
- `update(delta)`: plays the `move_<direction>` animation
- `physics_update(delta)`: calls `velocity_component.move(input)`; if input is empty → transitions to **Idle**

**`player_attack.gd`**
- `enter()`:
  1. Increments `PlayerActionManager.attack_state` (combo counter), wraps to 1 if it exceeds 4
  2. `anim_state = 1` on odd combo, `2` on even combo → produces alternating `attack_<dir>1` / `attack_<dir>2` animations (a 2-hit combo per direction)
  3. Plays the attack animation for the current direction & anim_state
  4. `await animation_finished` → automatically transitions back to **Idle**
- `update(delta)`: `velocity_component.attack_move(input)` — gives a lunge while attacking
- `exit()`: `velocity_component.stop_move()`

**`player_dash.gd`**
- Constant `DASH_TIME = 0.12`
- `enter()`: starts the timer, calls `velocity_component.dash(input)`
- `physics_update(delta)`: counts the timer down; when it runs out → `stop_move()`, then transitions to **Move** (if there is still input) or **Idle**

**State flow diagram**
```
       directional input
Idle ───────────────► Move
 ▲                      │
 │ no input              │ no input
 └──────────────────────┘

Idle/Move ──(attack button, can_attack)──► Attack ──(animation finished)──► Idle
Idle/Move ──(dash button, can_dash)──────► Dash   ──(timer expires)───────► Move / Idle
```
(Transitions into Attack/Dash are triggered from `player.gd`, not from the Idle/Move states themselves — see §5.7.)

### 5.9 `Scripts/Managers/PlayerActionManager.gd` (Autoload)
```gdscript
extends Node
```
| Var | Description |
|---|---|
| `attack_state: int` | attack combo counter (1–4, wraps) |
| `can_attack: bool` | attack lock gate |
| `can_dash: bool` | dash lock gate |

| Method | Description |
|---|---|
| `lock_attack(duration)` | `can_attack = false` → wait `duration` seconds → `can_attack = true` |
| `reset_attack_state()` | `attack_state = 0` (resets the combo) |
| `lock_dash(duration)` | same as `lock_attack` but for dash |

### 5.10 `Scripts/Components/heatlh_component.gd`
```gdscript
class_name HealthComponent extends Node
```
| Export var | Default | Description |
|---|---|---|
| `body` | — | owning CharacterBody2D |
| `body_sprite` | — | Sprite2D used for the flash effect |
| `velocity_component` | — | for triggering knockback from outside (see `damage_component.gd`) |
| `max_health`, `current_health` | 3.0 | HP (overridden to 100.0 for the Dummy in its scene) |

| Signal | Description |
|---|---|
| `get_damage` | Emitted every time `take_damage()` is called (no explicit listener yet in the current code — available for a future HP bar UI, etc.) |

| Method | Description |
|---|---|
| `take_damage(amount)` | Reduces HP, emits `get_damage`, calls `flash_hit()`, checks for death |
| `heal(amount)` | Increases HP, clamped to `max_health` |
| `die()` | `body.queue_free()` — **no death animation / item drop, the entity is simply removed** |
| `flash_hit()` (async) | Sets the shader param `hit_flash_on = true` for 0.2 seconds then back to `false` — the white-flash-on-hit effect |

### 5.11 `Scripts/Components/hitbox_component.gd`
```gdscript
class_name HitboxComponent extends Area2D
```
Purely a data container (no methods of its own) — an `Area2D` marking "the part of the body that can receive damage". Assigned to the `Hitable` group in the scene (plus `Player`/`player` specifically for the Player), so it can be filtered by `damage_component.gd`.

| Export var | Description |
|---|---|
| `body`, `health_component`, `velocity_component` | back-references to the owning entity |

### 5.12 `Scripts/Components/damage_component.gd`
```gdscript
extends Area2D
```
This is the **weapon hitbox** (the `SwordArea` on the Player) — the opposite of `HitboxComponent` (which receives damage, this one deals damage).

| Export var | Default | Description |
|---|---|---|
| `body` | — | owner of the weapon (Player) |
| `attack_damage` | 1.00 | damage per hit |

| Method | Description |
|---|---|
| `_on_area_entered(area)` | If the overlapping area is a `HitboxComponent`, is in the `Hitable` group, **and is not** in the `player` group (to prevent self-damage) → calls `take_damage()` on the target, then applies 200 knockback from `body`'s position |

### 5.13 `Scripts/Components/animation_player.gd`
```gdscript
extends AnimationPlayer
```
| Method | Description |
|---|---|
| `play_animation(action, direction, reverse_frame=false)` | Builds the animation name `"<action>_<direction>"` (e.g. `"move_down"`, `"attack_left1"`), checks `has_animation()`, plays it (backwards if `reverse_frame`), and returns the animation name; if it doesn't exist → `push_warning` |

### 5.14 `Scripts/Entity/Dummy/dummy.gd`
```gdscript
class_name Entity extends CharacterBody2D
```
The root script for `Dummy` — very minimal, just an `@export` container for wiring components (`health_component`, `hitbox_component`, `velocity_component`). No FSM, no AI — a static target used for testing combat.

### 5.15 `Scripts/Tiles/hazard_area.gd`
```gdscript
class_name hazard_area extends Area2D
```
> Note: the lowercase class name (`hazard_area`) breaks Godot's PascalCase convention for `class_name`, but it's still technically valid.

| Export var | Default | Description |
|---|---|---|
| `damage` | 2.00 | damage per contact tick (overridden to `0.1` in the `spikes.tscn` scene) |

| Method | Description |
|---|---|
| `_on_area_entered(area)` | If the area is a `HitboxComponent` → `area.health_component.take_damage(damage)` |

Used by the `Obstacles/spikes.tscn` scene and several spike instances (`Thorns` TileMapLayer) in `area_test.tscn`.

---

## 6. Scene Reference

### 6.1 `Scenes/Character/player.tscn`
```
Player (CharacterBody2D, script: player.gd, collision_mask=3)
├── Sprites (Node2D)
│   ├── Body (Sprite2D, 6×9 frame spritesheet, shader: flash_hit)
│   └── AnimationPlayer (17 animations: idle/move ×4 directions, attack ×4 directions ×2 combo, + RESET)
├── CollisionShape2D (Capsule, r=5 h=14)
├── StateMachine (Node)
│   ├── Idle
│   ├── Move
│   ├── Attack
│   └── Dash
├── InputComponent (Node)
├── VelocityComponent (Node, speed=80)
├── HealthComponent (Node, max_health=3)
├── HitboxComponent (Area2D, groups: Hitable, Player, player)
│   └── CollisionShape2D (Rectangle 8×12)
└── SwordArea (Area2D, damage_component.gd — invisible, collision toggled via animation track)
    └── CollisionShape2D (Rectangle 28×27, disabled by default)
```

**Important detail**: the animation tracks for each `attack_<dir>` **modify the position & `disabled` state of `SwordArea/CollisionShape2D`** in sync with the animation frames — the sword's collision is only active on the mid-swing frame (`times: [0, 0.1]`, `disabled: [false, true]`), and its position shifts to match the swing direction (`Vector2(0,16)` for down, `Vector2(-16,0)` for left, etc.).

### 6.2 `Scenes/Character/dummy.tscn`
```
CharacterBody2D (script: dummy.gd)
├── Sprite2D (shader: flash_hit)
├── CollisionShape2D (Capsule r=5 h=14)
├── HealthComponent (max_health=100)
├── HitboxComponent (Area2D, group: Hitable)
│   └── CollisionShape2D (Rectangle 10×18)
└── VelocityComponent (dummy_velocity.gd)
```
No `InputComponent`/`StateMachine` — the Dummy is purely passive, it can only receive damage & knockback.

### 6.3 `Scenes/Obstacles/spikes.tscn`
```
Spikes (Area2D, hazard_area.gd, damage=0.1)
├── Sprite2D
└── CollisionShape2D
```

### 6.4 `Scenes/UI/button.tscn`
```
Button (TextureButton)
  texture_normal / texture_focused from Assets/UIs/Button/
```
No script attached yet — a purely visual button template.

### 6.5 `Scenes/area_test.tscn` (⭐ Main Scene)
```
AreaTest (Node2D)
├── Tilemap (Node2D)
│   ├── Ground, Cliff1, Shadow, Thorns, Path, Tree  (all TileMapLayer, tileset: tile_set.tres)
│   └── (several spike Area2D instances on the Thorns layer wired to hazard_area.gd)
├── Player (instance of player.tscn)
│   └── Camera2D (zoom 1.4×, smoothing on)
└── Dummy (instance of dummy.tscn, test position at (127,-87))
```
A simple test level: layered grass/cliff/path/tree tilemaps, a spike area, one Player with a following camera, and one Dummy for combat practice.

### 6.6 `Scenes/propechy.tscn`
A separate showcase scene for the `sssss.gdshader` shader (see §9.2) — displays a "prophecy" sprite with an echo/scrolling effect over a blue background, with the Camera2D zoomed 4×. Appears to be an experimental/shader-test scene, not yet wired into the main gameplay.

---

## 7. Combat & Damage System — End-to-End Flow

1. The player presses **attack** → `player.gd._process()` checks `PlayerActionManager.can_attack` → locks it for 0.3s → the FSM switches to **Attack**.
2. **Attack.enter()** increments the combo counter, picks the `attack_<direction><1|2>` animation, and plays it.
3. The animation track enables `SwordArea` (`damage_component.gd`) right on the mid-swing frame, positioning it in the direction of the swing.
4. If `SwordArea` overlaps an enemy's `HitboxComponent` (in the `Hitable` group, not `player`) → `_on_area_entered()` calls `target.health_component.take_damage()` + `knockback()`.
5. `HealthComponent.take_damage()` reduces HP, triggers a **white flash** via the `flash_hit.gdshader` shader, and if HP ≤ 0 → `queue_free()` (the entity is removed immediately).
6. Once the attack animation finishes → automatically returns to **Idle**.
7. Alternative damage source: direct contact with `hazard_area.gd` (spikes) — no active attack needed, an overlapping `HitboxComponent` on a hazard area is enough.

---

## 8. Shaders

### 8.1 `Shaders/flash_hit.gdshader`
A simple `canvas_item` shader — 2 uniforms (`hit_flash_color`, `hit_flash_on`). When `hit_flash_on == true`, the sprite's color is entirely replaced with `hit_flash_color` (default white) while preserving the original alpha. Attached as the material on the Player & Dummy sprites, controlled from `HealthComponent.flash_hit()`.

### 8.2 `sssss.gdshader`
A much more complex shader — an "echo/afterimage + scrolling texture + bobbing" effect, used in the `propechy.tscn` showcase scene. Features:
- **Scrolling texture**: continuously shifts a secondary texture (`Scroll_Texture`) to act as a moving background.
- **Bobbing**: sinusoidal up-and-down sprite movement (`Height`, `Cycles`, `Offset`).
- **Echoes**: draws N progressively offset copies of the sprite with decaying alpha (`Distance`, `Count`, `Fade`), optionally in both directions (`Pulse_both_Directions`), with two blend modes (Mix / Additive) and a progressive color tint.
This shader is not currently used anywhere in the main gameplay — it looks like a visual/VFX experiment for a future feature (possibly a "phantom"/ghost effect or a mystical item, given the file name `my_propechy.png`).

---

## 9. Third-Party Addon — `discord-rpc-gd`

Located at `addons/discord-rpc-gd/`. This is an external addon (GDExtension, with `.so`/`.dll`/`.dylib` binaries for Linux/Windows/macOS) for **Discord Rich Presence** integration via the Discord Game SDK. It contains:
- `plugin.gd` — the editor plugin entry point
- `nodes/discord_autoload.gd` — an optional autoload node for RPC
- `nodes/debug.gd` + `Debug.tscn` — an in-editor debug panel
- `example.gd` — usage example

Current status: **the plugin is not enabled** — the `[editor_plugins]` section of `project.godot` still has `enabled=PackedStringArray()` (empty). So the addon is present in the project but is not yet enabled/used by the game's code.

---

## 10. Technical Notes & Potential Improvements

A few findings from the code analysis (not critical bugs, just cleanup notes for the future):

1. **Naming typos** — `heatlh_component.gd` (should be "health"), `state_mechine.gd` (should be "machine"), the `hazard_area` class isn't PascalCase. These don't affect functionality but could cause confusion during autocomplete/search.
2. **`InputComponent.attack_disabled`** is set up as a manual lock flag, but the `start_attack_cooldown()` function that would set it is commented out — attack cooldown locking is currently handled entirely by `PlayerActionManager`, so this field is effectively unused.
3. **`HealthComponent.die()`** calls `queue_free()` directly with no death animation, sound, item drop, or `died` signal — likely a placeholder for future development.
4. **Transitions into Attack/Dash** are triggered directly from `player.gd` (rather than from within the `Idle`/`Move` states), which is slightly inconsistent with a "pure" FSM pattern where all transition logic would ideally live inside the states themselves — but this is a valid design choice, since attack/dash can be triggered from any state (an interrupt).
5. Leftover Godot save artifacts were found that haven't been cleaned up: `Scenes/Character/filint.tscn*.tmp` (5 `.tmp` files) — safe to delete, usually left behind by an editor crash/autosave.
6. Some assets under `Assets/Unknown/` look duplicated/misspelled (`my_propechy.png` vs `my_prophecy.png`) — likely leftovers from experimentation that could be tidied up.
7. The `propechy.tscn` scene and `sssss.gdshader` shader still appear to be in the VFX-experimentation stage, not yet connected to `area_test.tscn` (the main scene).

---

## 11. Component Dependency Summary

```
PlayerActionManager (Autoload)
        ▲
        │ lock/read state
        │
   player.gd ──emit Transitioned──► StateMachine ──► Idle/Move/Attack/Dash (State)
        │                                                   │
        ├──uses──► InputComponent                            ├──uses──► VelocityComponent (player_velocity.gd)
        │                                                   └──uses──► AnimationPlayer (animation_player.gd)
        │
        └──has──► HealthComponent ──uses shader──► flash_hit.gdshader
                         ▲
                         │ take_damage()
                         │
        SwordArea (damage_component.gd) ──overlap──► HitboxComponent (target)
                                                              │
                                                     hazard_area.gd (spikes) can also trigger take_damage()
```

---

*This document was generated automatically from a direct reading of the repository's full source code (as of July 10, 2026). If the project structure changes, regenerating this document is recommended.*
