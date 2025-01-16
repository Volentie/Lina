class_name Objects

# Variables
static var mouse_input: Vector2 = Vector2.ZERO
static var picked_object: RigidBody3D = null
const RAY_LENGTH = 3
const OBJECT_OFFSET = 1
static var object_offset: float
static var object_offset_increment: float = 0
static var can_pickup = true
static var mouse_sensitivity: float = 0.1
static var highlighted_object: MeshInstance3D = null

const highligh_mat: ShaderMaterial = preload("res://Resources/materials/highlight.tres")

# Vector getters
static func get_mouse_pos(player: CharacterBody3D) -> Vector2:
	return player.get_viewport().get_mouse_position()

static func get_head_normal(player: CharacterBody3D) -> Vector3:
	return player.head.project_ray_normal(get_mouse_pos(player))

# Methods
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

static func cast_head_ray(player: CharacterBody3D, query_exclude: Array) -> Dictionary:
	var origin = player.head.project_ray_origin(get_mouse_pos(player))
	var space_state = player.get_world_3d().direct_space_state
	var end = origin + get_head_normal(player) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = query_exclude
	return space_state.intersect_ray(query)

static func handle_object_interaction(player: CharacterBody3D, delta: float) -> void:
	var origin = player.head.project_ray_origin(get_mouse_pos(player))
	# Cast a ray from the player's head to detect objects, get result as a dict
	var head_ray = cast_head_ray(player, [player])
	# Maintain picked object even if raycast loses sight
	if can_pickup and (picked_object or ("collider" in head_ray.keys() and head_ray.collider is RigidBody3D)):
		var object: RigidBody3D = picked_object if picked_object else head_ray.collider as RigidBody3D
		# If the object goes out of range using mouse scroll, release it
		if picked_object and picked_object.global_position.distance_to(origin) > RAY_LENGTH:
			release_object()
			return
		if object.get_meta("pickable", false):
			# If object's not counting collisions (or properly counting them), fix it
			if not object.contact_monitor or object.max_contacts_reported < 5:
				object.contact_monitor = true
				object.max_contacts_reported = 5
			# Release the object if the player is picking it up and collides with it in order to prevent surfing
			if object.get_contact_count() > 0:
				for collider in object.get_colliding_bodies():
					if collider.get_meta("Id", "") == "player":
						release_object()
						return
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
			var obj_final_pos = head_pos + get_head_normal(player) * object_offset
			var limit_factor = 0.35 / object.mass
			var motion_vector = ((obj_final_pos - object.global_position) / delta) * limit_factor
			object.linear_velocity = motion_vector  # Set velocity to move toward target

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

static func disable_object_highlight() -> void:
	if highlighted_object:
		highlighted_object.material_overlay = null
		highlighted_object = null

static func highlight_object(player: CharacterBody3D) -> void:
	var head_ray = cast_head_ray(player, [player])
	if "collider" in head_ray.keys():
		var mesh = head_ray.collider.get_parent() as MeshInstance3D
		if mesh and mesh.get_meta("Interactable", false):
			if mesh.material_overlay != highligh_mat:	
				mesh.material_overlay = highligh_mat
				highlighted_object = mesh
			return
	disable_object_highlight()
			