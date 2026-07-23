extends CharacterBody2D

@export var tile_size: int = 16
@export var mass: float = 5
@export var base_speed: float = 10
@export var push_delay: float = .5

var is_moving: bool = false
var contact_time: float = 0.0
var last_push_dir: Vector2 = Vector2.ZERO

func touch(direction: Vector2, delta: float) -> void:
	if is_moving:
		return

	if direction != last_push_dir:
		contact_time = 0.0
		last_push_dir = direction

	contact_time += delta

	if contact_time >= push_delay:
		contact_time = 0.0
		push(direction)

func release() -> void:
	contact_time = 0.0
	last_push_dir = Vector2.ZERO

func push(direction: Vector2) -> void:
	if is_moving:
		return

	var target_pos = global_position + direction * tile_size
	if _is_blocked(target_pos):
		return

	is_moving = true
	var actual_speed = base_speed / mass
	var duration = 1.0 / actual_speed

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(func(): is_moving = false)

func _is_blocked(target_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target_pos)
	query.exclude = [self]
	query.collision_mask = collision_mask
	var result = space_state.intersect_ray(query)
	return result.size() > 0
