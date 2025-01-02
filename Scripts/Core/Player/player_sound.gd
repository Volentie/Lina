class_name PlayerSound

# Load sounds
static var wood_footsteps = load("res://Resources/sounds/234263__fewes__footsteps-wood.ogg")
static var jump = load("res://Resources/sounds/jump.wav")
static var jumpland = load("res://Resources/sounds/jumpland.wav")
static var ants_walking = load("res://Resources/sounds/ants_walking.wav")

static func handle_sounds(streams: Dictionary) -> void:
	var walk_stream = streams["walk_stream"]
	var jump_stream = streams["jump_stream"]
	var env_stream = streams["env_stream"]
	
	# Handle environment sounds
	if !env_stream.playing:
		SoundHandler.set_play(env_stream, ants_walking, 0)
	
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
