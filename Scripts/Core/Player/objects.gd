class_name Objects

# Variables
static var mouse_input: Vector2 = Vector2.ZERO
static var picked_object: RigidBody3D = null
const RAY_LENGTH = 2
const OBJECT_OFFSET = 1
static var object_offset: float
static var object_offset_increment: float = 0
static var can_pickup = true
static var mouse_sensitivity: float = 0.1

static func handle_object_rotation(player: CharacterBody3D, object: RigidBody3D) -> void:
	# Get player's basis (local axes)
	var player_right = player.basis.x.normalized()    # Right direction
	var player_up = player.basis.y.normalized()       # Up direction

	# Calculate rotation deltas based on mouse input
	var rotate_up_down = mouse_input.y * mouse_sensitivity  # Up/Down rotation
	var rotate_left_right = mouse_input.x * mouse_sensitivity  # Left/Right rotation
	
	var rot_matrix_up_down = Basis(player_right, deg_to_rad(rotate_up_down))
	var rot_matrix_left_right = Basis(player_up, deg_to_rad(rotate_left_right))

	# Apply rotation to the object
	object.basis = rot_matrix_up_down * rot_matrix_left_right * object.basis
	mouse_input = Vector2.ZERO

static func release_object() -> void:
	if picked_object:
		can_pickup = false
		picked_object.gravity_scale = 1  # Re-enable object's gravity
		if picked_object.linear_velocity.length() > 0: # Slow down object to prevent object throwing
			picked_object.linear_velocity *= 0.5
		picked_object = null
		# Revert back to player camera mode
		PlayerStates.camera_mode.switch("Player")

static func handle_object_interaction(player: CharacterBody3D, origin: Vector3, head_normal: Vector3, result: Dictionary, delta: float, _tree: SceneTree) -> void:
	# Maintain picked object even if raycast loses sight
	if can_pickup and (picked_object or ("collider" in result.keys() and result.collider is RigidBody3D)):
		var object: RigidBody3D = picked_object if picked_object else result.collider as RigidBody3D
		# # If the object goes out of range using mouse scroll, release it
		# if picked_object and picked_object.global_position.distance_to(origin) > RAY_LENGTH:
		# 	release_object()
		# 	return
		if object.name.find("$INTB$") != -1:
			# Clear rotation velocity
			if object.angular_velocity.length() > 0:
				object.angular_velocity = Vector3.ZERO
			# Register picked object
			if not picked_object:
				picked_object = object
				object_offset = (object.global_position - player.head.global_transform.origin).length()
				object.gravity_scale = 0  # Disable gravity
				# Reset object's velocity
				object.linear_velocity = Vector3.ZERO

			# Compute the target position
			var head_pos = player.head.global_transform.origin
			var obj_final_pos = head_pos + head_normal * object_offset / 1.1
			var limit_factor = 0.35 / object.mass
			var motion_vector = ((obj_final_pos - object.global_position) / delta) * limit_factor
			
			var world = player.get_world_3d()
			var ray_origin = object.global_position
			var ray_target = obj_final_pos
			var hit = Utils.cast_ray(world, ray_origin, ray_target, [object, player])

			if hit.is_empty():
				object.linear_velocity = motion_vector
			else:
				release_object()
				return

			# Scroll to move object closer or further
			if object_offset_increment != 0:
				object_offset += object_offset_increment
				object_offset_increment = 0
			if object.get_colliding_bodies().size() > 0 and object.global_position.distance_to(obj_final_pos) >= 1:
				object.linear_velocity = Vector3.ZERO
				release_object()
				return
			# Handle objects rotation
			if PlayerStates.camera_mode.get_cur_state_name() == "Object":
				handle_object_rotation(player, object)
