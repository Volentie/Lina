class_name PlayerSound extends Node3D

# Load sounds
static var wood_footsteps = load("res://Resources/sounds/234263__fewes__footsteps-wood.ogg")
static var jump = load("res://Resources/sounds/jump.wav")
static var jumpland = load("res://Resources/sounds/jumpland.wav")
static var ants_walking = load("res://Resources/sounds/ants_walking.wav")
static var ambience_the_mystery_mx_1 = load("res://Resources/sounds/ambience_the_mystery_mx_1.wav")
static var environment: Resource = ants_walking
static var walk_stream
static var jump_stream
static var env_stream

static func play_environment(env: Resource) -> void:
	environment = env
	SoundHandler.set_play(env_stream, environment, 0)

static func handle_sounds(streams: Dictionary) -> void:
	walk_stream = streams["walk_stream"]
	jump_stream = streams["jump_stream"]
	env_stream = streams["env_stream"]
	
	# Handle jump and landing sounds
	if PlayerStates.general_mode.get_cur_state_name() == "Jumping":
		jump_stream.pitch_scale = randf_range(0.8, 1.2)
		SoundHandler.set_play_once(jump_stream, jumpland, func():
			PlayerStates.general_mode.switch("Air")
		)

	if PlayerStates.general_mode.get_cur_state_name() == "Walking":
		SoundHandler.set_play(walk_stream, wood_footsteps, randf() * 0.3)
		if walk_stream.playing and PlayerStates.general_mode.get_last_state_name() == "Running":
			walk_stream.pitch_scale = lerp(walk_stream.pitch_scale, 0.8, 0.1)
	elif PlayerStates.general_mode.get_cur_state_name() == "Running":
		walk_stream.pitch_scale = lerp(walk_stream.pitch_scale, 1.0, 0.1)
		if !walk_stream.playing:
			SoundHandler.set_play(walk_stream, wood_footsteps, randf() * 0.3)
	else:
		SoundHandler.stop(walk_stream)
