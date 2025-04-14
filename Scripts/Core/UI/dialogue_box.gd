class_name Dialogue extends Control

# TODO: Refactor so it processes _process here and supports multiple dialogues

static var current_line := 0
static var lines := {
	"Intro":
	[
		"Lina...?",
		"Where are you?",
		"You mean so much to me.",
		"You can't just vanish like that!"
	]
}
static var instance: Dialogue

static var finished = {
	"Intro": false
}

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		push_warning("Dialogue.instance was already registered.")

static func update_label(line: String) -> void:
	var label = instance.get_node("Panel/Label")
	label.text = line

static func play_dialogue(dialogue_type: String) -> void:
	PlayerStates.general_mode.switch("Intro")
	
	if instance == null:
		push_error("Dialogue.instance is null")
		return
	
	var line = lines[dialogue_type]
	update_label(line[current_line])

	if Input.is_action_just_pressed("ui_confirm"):
		if current_line + 1 >= line.size():
			finished[dialogue_type] = true
			PlayerStates.general_mode.switch("Idle")
			instance.queue_free() # Delete the node at the end of the current frame
		else:
			current_line += 1
			update_label(line[current_line])
