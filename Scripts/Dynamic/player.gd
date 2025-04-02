extends CharacterBody3D

# References
@onready var head = $player_camera
@onready var walk_stream = $walk_stream
@onready var jump_stream = $jump_stream
@onready var env_stream = $env_stream
@onready var animation_player = $"../animation_player"
@onready var door_label = $"../UI/door_label"
@onready var area_3d: Area3D = $Area3D

# Variables
const RAY_LENGTH = 2

func _ready() -> void:
	PlayerStates.general_mode.switch("Idle")
	PlayerStates.speed_mode.switch("Walk")
	PlayerStates.camera_mode.switch("Player")
	# Mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Setup interactable objects
	var home: Node3D = get_tree().root.get_child(0).find_child("home")
	for obj in home.get_children(false):
		if obj.name.find("$INTB$") != -1:
			if not obj.contact_monitor:
				obj.contact_monitor = true
				obj.max_contacts_reported = 5
			if not obj.continuous_cd:
				obj.continuous_cd = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Objects.mouse_input += event.relative
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Objects.object_offset_increment = 0.1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Objects.object_offset_increment = -0.1

func cast_ray() -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	#Raycast
	var origin = head.project_ray_origin(mouse_pos)
	var head_normal = head.project_ray_normal(mouse_pos)
	var end = origin + head_normal * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	return {
		"origin": origin,
		"head_normal": head_normal,
		"result": result
	}

func _physics_process(delta: float) -> void:
	# Camera
	if PlayerStates.camera_mode.get_cur_state_name() == "Player":
		Camera.handle_camera_rotation(self)

	# Raycast
	var ray_dict: Dictionary = cast_ray()
	var origin = ray_dict.get("origin")
	var head_normal = ray_dict.get("head_normal")
	var result = ray_dict.get("result")

	if Doors.is_door(result):
		Doors.label_door(door_label)
		if Input.is_action_pressed("action_interact"):
			Doors.open_door(animation_player)
	else:
		if Doors.is_labeled:
			Doors.unlabel_door(door_label)
		
	# Handle object interaction
	if Input.is_action_pressed("action_attack"):
		Objects.handle_object_interaction(self, origin, head_normal, result, delta)

	if Input.is_action_just_released("action_attack"):
		Objects.release_object()
		Objects.can_pickup = true
	if Objects.picked_object:
		if Input.is_action_just_pressed("camera_mode_object"):
			PlayerStates.camera_mode.switch("Object")
		elif Input.is_action_just_released("camera_mode_object"):
			PlayerStates.camera_mode.switch("Player")

	# Apply movement
	move_and_slide()

	# Movement
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= basis.z
	if Input.is_action_pressed("move_backward"):
		direction += basis.z
	if Input.is_action_pressed("move_left"):
		direction -= basis.x
	if Input.is_action_pressed("move_right"):
		direction += basis.x

	# Normalize direction so that diagonal movement isn't faster	
	direction = direction.normalized()

	# Alter speed
	if Input.is_action_just_pressed("speedmode_run"):
		PlayerStates.speed_mode.switch("Run")
	if Input.is_action_just_released("speedmode_run"):
		PlayerStates.speed_mode.switch("Walk")

	var dir_force: Vector3 = direction * PlayerConfig.speed
	var force = Vector3(dir_force.x, velocity.y, dir_force.z)

	# Ground logic
	if is_on_floor():
		# Handle ground movement
		# If the player is moving, lerp faster to the new velocity
		if direction.length() > 0:
			# Handle walking/running state
			if PlayerStates.speed_mode.get_cur_state_name() == "Run":
				PlayerStates.general_mode.switch("Running")
			else:
				PlayerStates.general_mode.switch("Walking")
			velocity = lerp(velocity, force, 0.9)
		else: # If not, lerp slower to 0
			velocity = lerp(velocity, force, 0.2)
			# Switch to idle state
			PlayerStates.general_mode.switch("Idle")
		# Jump
		if Input.is_action_just_pressed("action_jump"):
			velocity.y += (PlayerConfig.jump_scale * 150) * delta
			PlayerStates.general_mode.switch("Jumping")
	else:
		# Switch to air mode if not jumping
		if PlayerStates.general_mode.get_cur_state_name() != "Jumping":
			PlayerStates.general_mode.switch("Air")
		# Handle air movement (more like gliding)
		velocity = lerp(velocity, force, 0.1)
		# Apply gravity
		velocity.y -= (PlayerConfig.gravity_scale * 2.5) * delta
	

# Handle sounds
func _process(_delta: float) -> void:
	PlayerSound.handle_sounds({
		"walk_stream": walk_stream,
		"jump_stream": jump_stream,
		"env_stream": env_stream
	})
