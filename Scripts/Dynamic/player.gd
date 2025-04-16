extends CharacterBody3D

# References
@onready var head = $player_camera
@onready var walk_stream = $walk_stream
@onready var jump_stream = $jump_stream
@onready var env_stream = $env_stream
@onready var animation_player = $"../animation_player"
@onready var door_label = $"../UI/door_label"
@onready var area_3d: Area3D = $Area3D
@onready var player_body = $player_body
@onready var interact_label: Label = $"../UI/interaction_label"
var interactable_target: Node = null

var allow_input = false

# Variables
const RAY_LENGTH = 2

func _ready() -> void:
	PlayerStates.speed_mode.switch("Walk")
	PlayerStates.camera_mode.switch("Player")
	
	Dialogue.play_dialogue("Intro", func():
		PlayerStates.general_mode.switch("Intro")
	)
	
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
			obj.collision_layer = (1 << 3)
			obj.collision_mask = (1 << 0) | (1 << 3)

func _input(event: InputEvent) -> void:
	# Don't register mouse input while in 'intro' mode
	if PlayerStates.general_mode.get_cur_state_name() == "Intro":
		return
	
	if event.is_action_pressed("action_interact"):
		if interactable_target and interactable_target.has_method("interact"):
			interactable_target.interact()
			
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Objects.mouse_input += event.relative
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Objects.object_offset_increment = 0.1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Objects.object_offset_increment = -0.1

func hit_valid(hit: Dictionary) -> Dictionary:
	if hit and hit.has("collider"):
		return hit
	return {}

func _physics_process(delta: float) -> void:
	if PlayerStates.general_mode.get_cur_state_name() == "Intro":
		return
	# Camera
	if PlayerStates.camera_mode.get_cur_state_name() == "Player":
		Camera.handle_camera_rotation(self)

	# Raycast setup
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var origin = head.project_ray_origin(mouse_pos)
	var head_normal = head.project_ray_normal(mouse_pos)
	var from = head.project_ray_origin(mouse_pos)
	var to = origin + head_normal * RAY_LENGTH
	var world = get_world_3d()
	var hit = Utils.cast_ray(world, from, to, [self])	
	
	if hit_valid(hit):
		if Doors.is_door(hit):
			Doors.label_door(door_label)
			if Input.is_action_pressed("action_interact"):
				Doors.open_door(animation_player)
		# Handle dialogue_interactable objects
		if hit.collider.get_parent() and hit.collider.get_parent().has_method("interact"):
			interactable_target = hit.collider.get_parent()
			interact_label.text = "Interact [E]"
			interact_label.visible = true
	else:
		if Doors.is_labeled:
			Doors.unlabel_door(door_label)
		if interact_label.visible:
			interact_label.visible = false
		interactable_target = null
	# Handle object interaction
	# out of hit_valid because the first check can be passed either by a valid hit or if there is a picked_object
	# (it does it's own check)
	if Input.is_action_pressed("action_attack"):
		Objects.handle_object_interaction(self, origin, head_normal, hit, delta, get_tree())

	if Input.is_action_just_released("action_attack"):
		Objects.release_object()
		Objects.can_pickup = true
	if Objects.picked_object:
		if Input.is_action_just_pressed("camera_mode_object"):
			PlayerStates.camera_mode.switch("Object")
		elif Input.is_action_just_released("camera_mode_object"):
			PlayerStates.camera_mode.switch("Player")

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
		velocity.y = clamp(velocity.y, -50.0, 50.0)

	# Apply movement
	move_and_slide()

# Handle sounds
func _process(_delta: float) -> void:
	PlayerSound.handle_sounds({
		"walk_stream": walk_stream,
		"jump_stream": jump_stream,
		"env_stream": env_stream
	})
