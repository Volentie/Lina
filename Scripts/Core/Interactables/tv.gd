extends Interactable

func interact() -> void:
	if Dialogue.instance:
		var duration := 1.5
		Dialogue.play_dialogue("TV", func():
			await Engine.get_main_loop().create_timer(duration).timeout
			Dialogue.hide_dialogue()
		)
