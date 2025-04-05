class_name Utils

static func cast_ray(
	world: World3D,
	from: Vector3,
	to: Vector3,
	exclude: Array = [],
	collision_mask: int = 0xFFFFFFFF
) -> Dictionary:
	# Creates a raycast query between two points, with support for exclusions and collision mask.
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	query.collision_mask = collision_mask

	return world.direct_space_state.intersect_ray(query)