extends CharacterBody3D

# References
@onready var head = $player_camera
@onready var walk_stream = $walk_stream
@onready var jump_stream = $jump_stream
@onready var env_stream = $env_stream

func _ready() -> void:
	PlayerStates.general_mode.switch("Idle")
	PlayerStates.speed_mode.switch("Walk")
	PlayerStates.camera_mode.switch("Player")
	# Mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

func _physics_process(delta: float) -> void:
	# Camera
	if PlayerStates.camera_mode.get_cur_state_name() == "Player":
		Camera.handle_camera_rotation(self)
	
	if Objects.picked_object:
		if Input.is_action_just_pressed("camera_mode_object"):
			PlayerStates.camera_mode.switch("Object")
		elif Input.is_action_just_released("camera_mode_object"):
			PlayerStates.camera_mode.switch("Player")

	# Apply movement
	move_and_slide()

	# Handle object interaction
	if Input.is_action_pressed("action_attack"):
		Objects.handle_object_interaction(self, delta)
	elif Input.is_action_just_released("action_attack"):
		Objects.release_object()
		Objects.can_pickup = true

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