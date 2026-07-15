# Project Next Documentation

## Overview

# `project-next-main/Scripts/Components/animation_player.gd`

```gdscript
extends AnimationPlayer

func play_animation(action: String, direction: String, reverse_frame: bool = false):
    var anim_name = "%s_%s" % [action, direction]
    if has_animation(anim_name):
        if reverse_frame:
            play_backwards(anim_name)
        play(anim_name)
        return anim_name
    else:
        push_warning("Missing animation: %s" % anim_name)
```

# `project-next-main/Scripts/Components/damage_component.gd`

```gdscript
extends Area2D

@export var body: CharacterBody2D
@export var attack_damage: float = 1.00

func _on_area_entered(area: Area2D) -> void:
    if area is HitboxComponent and area.is_in_group("Hitable") and not area.is_in_group("player"):
        area.health_component.take_damage(attack_damage)
        area.get_parent().velocity_component.knockback(100, body.velocity_component.get_direction_vector())
```

# `project-next-main/Scripts/Components/dummy/dummy_velocity.gd`

```gdscript
extends VelocityComponent


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
    body.move_and_slide()
    pass
```

# `project-next-main/Scripts/Components/heatlh_component.gd`

```gdscript
extends Node
class_name HealthComponent

@export var body: CharacterBody2D
@export var body_sprite: Sprite2D
@export var velocity_component: VelocityComponent
@export var max_health = 3.0
@export var current_health = 3.0

signal get_damage

func take_damage(amount: float):
    current_health -= amount
    get_damage.emit()
    flash_hit()
    if current_health <= 0:
        die()

func heal(amount: float):
    current_health += amount
    if current_health > max_health:
        current_health = max_health

func die():
    body.queue_free()

func flash_hit():
    body_sprite.material.set_shader_parameter("hit_flash_on", true)
    await get_tree().create_timer(.2, true, false, true).timeout
    body_sprite.material.set_shader_parameter("hit_flash_on", false)
```

# `project-next-main/Scripts/Components/hitbox_component.gd`

```gdscript
extends Area2D
class_name HitboxComponent

@export var body: CharacterBody2D
@export var health_component: HealthComponent
```

# `project-next-main/Scripts/Components/player/input_component.gd`

```gdscript
extends Node
class_name InputComponent

signal direction_changes

var last_direction := Vector2.ZERO
var direction_changed := false
var attack_disabled := false

func _process(_delta: float) -> void:
    var current_direction = get_input_direction()
    if current_direction != last_direction:
        last_direction = current_direction
        direction_changed = true
        emit_signal("direction_changes")

func get_input_direction() -> Vector2:
    return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func attack() -> bool:
    if attack_disabled:
        return false
    return Input.is_action_just_pressed("attack")

func dash() -> bool:
    return Input.is_action_just_pressed("dash")

#func start_attack_cooldown(duration: float) -> void:
    #attack_disabled = true
    #await get_tree().create_timer(duration).timeout
    #attack_disabled = false
```

# `project-next-main/Scripts/Components/player/player.gd`

```gdscript
extends CharacterBody2D

@export var velocity_component: VelocityComponent
@export var health_component: HealthComponent
@export var hitbox_component: HitboxComponent
@export var state_machine: StateMachine
@export var animation_player: AnimationPlayer
@export var input_component: InputComponent

var no_attack_time := 0.0 # time to reset attack
const attack_RESET_DELAY := 1.0 # reset time

var no_dash_time := 0.0
const dash_RESET_DELAY := 1.0

func _process(delta: float) -> void:
    if input_component.attack():
        no_attack_time = 0.0

        if PlayerActionManager.can_attack:
            PlayerActionManager.lock_attack(0.3)
            state_machine.current_state.Transitioned.emit(state_machine.current_state, "Attack")
    else:
        no_attack_time += delta

        if no_attack_time >= attack_RESET_DELAY:
            PlayerActionManager.reset_attack_state()

    if input_component.dash():
        if PlayerActionManager.can_dash:
            PlayerActionManager.lock_dash(0.5)
            state_machine.current_state.Transitioned.emit(state_machine.current_state, "Dash")
```

# `project-next-main/Scripts/Components/player/player_attack.gd`

```gdscript
extends State

var anim_state

func enter():
    PlayerActionManager.attack_state += 1
    if PlayerActionManager.attack_state > 4:
        PlayerActionManager.attack_state = 1

    anim_state = 1 if PlayerActionManager.attack_state % 2 != 0 else 2

    var dir = velocity_component.current_direction + str(anim_state)
    animation_player.play_animation("attack", dir)

    await animation_player.animation_finished
    #await get_tree().create_timer(.3).timeout
    Transitioned.emit(self, "Idle")


func update(_delta: float):
    velocity_component.attack_move(input.get_input_direction())

func exit():
    velocity_component.stop_move()
```

# `project-next-main/Scripts/Components/player/player_dash.gd`

```gdscript
extends State

const DASH_TIME := 0.12

var timer := 0.0

func enter():
    timer = DASH_TIME
    velocity_component.dash(input.get_input_direction())

func physics_update(delta):
    timer -= delta
    if timer <= 0:
        velocity_component.stop_move()
        if input.get_input_direction() == Vector2.ZERO:
            Transitioned.emit(self, "Idle")
        else:
            Transitioned.emit(self, "Move")
```

# `project-next-main/Scripts/Components/player/player_idle.gd`

```gdscript
extends State

func enter():
    pass

func update(_delta: float):
    var direction = velocity_component.current_direction
    animation_player.play_animation("idle", direction)

func physics_update(_delta: float):
    if input.get_input_direction() != Vector2.ZERO:
        Transitioned.emit(self, "Move")
```

# `project-next-main/Scripts/Components/player/player_move.gd`

```gdscript
extends State

func enter():
    pass

func update(_delta):
    var direction = velocity_component.current_direction
    animation_player.play_animation("move", direction)

func physics_update(_delta):
    velocity_component.move(input.get_input_direction()) # Moving the player based on input

    # Trigger for trantiton to idle state
    if input.get_input_direction() == Vector2.ZERO:
        #await get_tree().create_timer(0.1).timeout #await for the animation doesn't change immediately
        #await animation_player.animation_finished
        Transitioned.emit(self, "Idle")
```

# `project-next-main/Scripts/Components/player/player_velocity.gd`

```gdscript
extends VelocityComponent

@export var input_component: InputComponent
var input_direction: Vector2

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
    var input_dir = input_component.get_input_direction()

    # Update internal direction states
    last_direction = current_direction
    if input_dir.length() > 0:
        current_direction = get_direction_name(input_dir, current_direction)
    else:
        pass

    # Move body
    body.move_and_slide()

func move(direction: Vector2, _speed = speed):
    body.velocity = direction.normalized() * _speed

func attack_move(direction: Vector2):
    body.velocity = direction * (speed * 3) # faster for a burst
    if direction == Vector2.ZERO:
        body.velocity = get_direction_vector() * (speed * .5) # faster for a burst but if not input
    await get_tree().create_timer(0.1).timeout
    body.velocity = Vector2.ZERO

func dash(direction: Vector2):
    body.velocity = direction * (speed * 5)
    if body.velocity == Vector2.ZERO:
        body.velocity = get_direction_vector() * (speed * 5)
    await get_tree().create_timer(0.1).timeout
    body.velocity = Vector2.ZERO
```

# `project-next-main/Scripts/Components/state.gd`

```gdscript
class_name State extends Node

@export var body: CharacterBody2D
@export var state_machine: StateMachine
@export var animation_player: AnimationPlayer
@export var velocity_component: VelocityComponent
@export var input: InputComponent #assign to input component if needed

@warning_ignore("unused_signal")
signal Transitioned

func enter():
    pass

func update(_delta: float):
    pass

func physics_update(_delta: float):
    pass

func exit():
    pass
```

# `project-next-main/Scripts/Components/state_mechine.gd`

```gdscript
class_name StateMachine extends Node

@export var initial_state : State
@export var current_state : State
var states : Dictionary = {}  # Store states by name for lookup

func _ready() -> void:
    for child in get_children():
        if child is State:
            # Store each State in the dictionary, using lowercase of its name as the key
            states[child.name.to_lower()] = child
            # Connect state's Transitioned signal to the handler
            child.Transitioned.connect(on_child_transition)

    if initial_state:
        initial_state.enter()
        current_state = initial_state

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func on_child_transition(state, new_state_name):
    # Only process transition if it's from the currently active state
    if state != current_state:
        return

    var new_state = states.get(new_state_name.to_lower())
    if !new_state:
        return  # No such state found

    if current_state:
        current_state.exit()  # Call Exit on the current state

    current_state = new_state  # Update the current state reference
    new_state.enter()  # Enter the new state
```

# `project-next-main/Scripts/Components/velocity_component.gd`

```gdscript
class_name VelocityComponent extends Node

@export var speed: float = 100.00
@export var body: CharacterBody2D

var initial_direction: String = "down"
var current_direction: String = "down"
var last_direction: String = "down"

func get_direction_name(input_vector: Vector2, previous_direction: String) -> String:
    var directions = []

    if input_vector.x < 0:
        directions.append("left")
    elif input_vector.x > 0:
        directions.append("right")

    if input_vector.y < 0:
        directions.append("up")
    elif input_vector.y > 0:
        directions.append("down")

    # If nothing pressed, return previous direction
    if directions.is_empty():
        return previous_direction

    # If only one direction, return it
    if directions.size() == 1:
        return directions[0]

    # If current direction is still pressed, keep it
    if directions.has(previous_direction):
        return previous_direction

    # Else, pick one randomly or by priority
    # Priority order: down > up > left > right
    for dir in ["down", "up", "left", "right"]:
        if directions.has(dir):
            return dir

    return directions[0]  # Fallback

func get_direction_vector():
    var directions_mapping: Dictionary = {
        "down" : Vector2.DOWN,
        "up" : Vector2.UP,
        "left" : Vector2.LEFT,
        "right" : Vector2.RIGHT
    }
    return directions_mapping.get(current_direction)
    @warning_ignore("unreachable_code")
    print(directions_mapping)

func knockback(knockback_power: float, knockback_origin: Vector2) -> void:
    var knockback_direction = (knockback_origin -body.velocity.normalized()) * knockback_power
    body.velocity = knockback_direction
    await get_tree().create_timer(0.1).timeout
    stop_move()

func stop_move():
    body.velocity = Vector2.ZERO
```

# `project-next-main/Scripts/Entity/Dummy/dummy.gd`

```gdscript
extends CharacterBody2D
class_name Entity

@export var health_component: HealthComponent
@export var hitbox_component: HitboxComponent
@export var velocity_component: VelocityComponent
```

# `project-next-main/Scripts/Managers/PlayerActionManager.gd`

```gdscript
extends Node

var attack_state := 0
var can_attack := true
var can_dash:= true

func lock_attack(duration: float) -> void:
    can_attack = false
    await get_tree().create_timer(duration).timeout
    can_attack = true

func reset_attack_state():
    attack_state = 0

func lock_dash(duration: float) -> void:
    can_dash = false
    await get_tree().create_timer(duration).timeout
    can_dash = true

```

# `project-next-main/addons/discord-rpc-gd/example.gd`

```gdscript
class_name DiscordRPCTutorial
extends Node

## 1. Put the addons/ folder in your Godot project[br]
## 2. Enable the addon in your Project Settings under "Plugins" and "DiscordRPC". [br](if it doesn't show up restart your project and try again)[br]
## 3. Restart your project[br]
## 4. Create an Application under https://discord.com/developers/applications and get the Application ID br]
## 5. (optional) Set images under "Rich Presence" and "Art Assets" and remember the keys[br]
##
## This is your [code]_ready()[/code] function wich could be anywhere
## [codeblock]
## func _ready():
##     # Application ID
##     DiscordRPC.app_id = 1099618430065324082
##     # this is boolean if everything worked
##     print("Discord working: " + str(DiscordRPC.get_is_discord_working()))
##     # Set the first custom text row of the activity here
##     DiscordRPC.details = "A demo activity by vaporvee#1231"
##     # Set the second custom text row of the activity here
##     DiscordRPC.state = "Checkpoint 23/23"
##     # Image key for small image from "Art Assets" from the Discord Developer website
##     DiscordRPC.large_image = "game"
##     # Tooltip text for the large image
##     DiscordRPC.large_image_text = "Try it now!"
##     # Image key for large image from "Art Assets" from the Discord Developer website
##     DiscordRPC.small_image = "boss"
##     # Tooltip text for the small image
##     DiscordRPC.small_image_text = "Fighting the end boss! D:"
##     # "02:41 elapsed" timestamp for the activity
##     DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
##     # "59:59 remaining" timestamp for the activity
##     DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600
##     # Always refresh after changing the values!
##     DiscordRPC.refresh()
## [/codeblock]
##
## @tutorial(More information here): https://github.com/vaporvee/discord-rpc-godot/wiki/Quick-start
## @tutorial(Make your Application ID and else here): https://discord.com/developers/applications
```

# `project-next-main/addons/discord-rpc-gd/nodes/debug.gd`

```gdscript
## This is a Debug Node wich will show some usefull info and buttons/input
##
## The DiscordRPC Debug Node will show info about the current values of its variables and some buttons to change them.
##
## @tutorial: https://github.com/vaporvee/discord-rpc-godot/wiki
@tool
extends Node

func _ready() -> void:
    const DebugNodeGroup: PackedScene = preload("res://addons/discord-rpc-gd/nodes/Debug.tscn")
    add_child(DebugNodeGroup.instantiate())
```

# `project-next-main/addons/discord-rpc-gd/nodes/discord_autoload.gd`

```gdscript
## This is a GDscript Node wich gets automatically added as Autoload while installing the addon.
##
## It can run in the background to comunicate with Discord.
## You don't need to use it. If you remove it make sure to run [code]DiscordRPC.run_callbacks()[/code] in a [code]_process[/code] function.
##
## @tutorial: https://github.com/vaporvee/discord-rpc-godot/wiki
extends Node

func _ready() -> void:
    pass

func  _process(_delta) -> void:
    DiscordRPC.run_callbacks()
```

# `project-next-main/addons/discord-rpc-gd/plugin.gd`

```gdscript
@tool
extends EditorPlugin

const DiscordRPCDebug = preload("res://addons/discord-rpc-gd/nodes/debug.gd")
const DiscordRPCDebug_icon = preload("res://addons/discord-rpc-gd/Debug.svg")
var loaded_DiscordRPCDebug = DiscordRPCDebug.new()
var restart_window: ConfirmationDialog = preload("res://addons/discord-rpc-gd/restart_window.tscn").instantiate()
var plugin_cfg: ConfigFile = ConfigFile.new()
const plugin_data_filename = "/plugin_data.cfg"

func _enter_tree() -> void:
    add_custom_type("DiscordRPCDebug","Node",DiscordRPCDebug,DiscordRPCDebug_icon)
    get_editor_interface().get_editor_settings().settings_changed.connect(_on_editor_settings_changed)

func _ready() -> void:
    await get_tree().create_timer(0.5).timeout
    plugin_cfg.load(get_editor_interface().get_editor_paths().get_data_dir() + plugin_data_filename)
    if !get_editor_interface().get_editor_settings().has_setting("DiscordRPC/EditorPresence/enabled"):
        get_editor_interface().get_editor_settings().set_setting("DiscordRPC/EditorPresence/enabled",plugin_cfg.get_value("Discord","editor_presence",false))

func _exit_tree():
    if get_editor_interface().get_editor_settings().has_setting("DiscordRPC/EditorPresence/enabled"):
        get_editor_interface().get_editor_settings().erase("DiscordRPC/EditorPresence/enabled")

func _enable_plugin() -> void:
    if FileAccess.file_exists(ProjectSettings.globalize_path("res://") + "addons/discord-rpc-gd/bin/.gdignore"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path("res://") + "addons/discord-rpc-gd/bin/.gdignore")
    add_autoload_singleton("DiscordRPCLoader","res://addons/discord-rpc-gd/nodes/discord_autoload.gd")
    restart_window.connect("confirmed", save_no_restart)
    restart_window.connect("canceled", save_and_restart)
    get_editor_interface().popup_dialog_centered(restart_window)
    print("IGNORE RED ERROR MESSAGES BEFORE THE SECOND RESTART!")

func _disable_plugin() -> void:
    remove_autoload_singleton("DiscordRPCLoader")
    FileAccess.open("res://addons/discord-rpc-gd/bin/.gdignore",FileAccess.WRITE)
    remove_custom_type("DiscordRPCDebug")
    get_editor_interface().get_editor_settings().erase("DiscordRPC/EditorPresence/enabled")
    push_warning("Please restart the editor to fully disable the DiscordRPC plugin")

func save_and_restart() -> void:
    get_editor_interface().restart_editor(true)

func save_no_restart() -> void:
    get_editor_interface().restart_editor(false)

var editor_presence: Node
func _on_editor_settings_changed() -> void:
    plugin_cfg.set_value("Discord","editor_presence",get_editor_interface().get_editor_settings().get_setting("DiscordRPC/EditorPresence/enabled"))
    plugin_cfg.save(get_editor_interface().get_editor_paths().get_data_dir() + plugin_data_filename)
    if ClassDB.class_exists("EditorPresence") && editor_presence == null:
        editor_presence = ClassDB.instantiate("EditorPresence")
    if get_editor_interface().get_editor_settings().has_setting("DiscordRPC/EditorPresence/enabled") && get_editor_interface().get_editor_settings().get_setting("DiscordRPC/EditorPresence/enabled"):
        add_child(editor_presence)
    else:
        editor_presence.queue_free()
```
