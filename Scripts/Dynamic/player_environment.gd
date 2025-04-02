extends Area3D

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("environment"):
		# Wait for the env_stream to be setup
		while not PlayerSound.env_stream:
			await get_tree().create_timer(0.1).timeout
		if area.get_meta("env_bedroom", false):
			PlayerSound.play_environment(PlayerSound.ambience_the_mystery_mx_1)
		if area.get_meta("env_livingroom", false):
			PlayerSound.play_environment(PlayerSound.ants_walking)
