class_name Camera

static func handle_camera_rotation(player: CharacterBody3D) -> void:
	player.head.rotation_degrees.x -= Objects.mouse_input.y * Objects.mouse_sensitivity
	player.rotation_degrees.y -= Objects.mouse_input.x * Objects.mouse_sensitivity
	player.head.rotation_degrees.x = clamp(player.head.rotation_degrees.x, -90, 90)
	Objects.mouse_input = Vector2.ZERO
