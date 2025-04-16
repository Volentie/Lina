class_name Dialogue extends Control

static var current_line: int
static var dialogue_type := ""
static var label: Label
static var lines := {
	"Intro":
	[
		"Lina...?",
		"Where are you?",
		"You mean so much to me.",
		"You can't just vanish like that!"
	],
	"TV": [
		"It's just static...",
		"Maybe it's trying to tell me something."
	]
}
signal dialogue_finished(dialogue_type: String) # TODO: Use it as a signal to some activity

static var instance: Dialogue
static var dialogue_playing := false

func _ready() -> void:
	if instance == null:
		instance = self
		label = instance.get_node("Panel/Label")
	else:
		push_warning("Dialogue.instance was already registered.")

static func update_label(line: String) -> void:
	if instance == null:
		push_warning("Dialogue.instance is null")
		return
	label.text = line

static func play_dialogue(diag_type: String, on_dialogue_start: Callable = Callable() ) -> void:
	# Check if dialogue is already playing somewhere else
	if dialogue_playing:
		push_warning("Dialogue already in progress.")
		return
	# Always reset the current line
	current_line = 0
	dialogue_playing = true	
	dialogue_type = diag_type

	# Wait for instance so label can be assigned
	while instance == null:
		await Engine.get_main_loop().create_timer(0.1).timeout
		print("Waiting for Dialogue.instance...")

	# Set instance to visible
	instance.visible = true
		
	update_label(lines[dialogue_type][current_line])

	if on_dialogue_start.is_valid():
		match on_dialogue_start.get_argument_count():
			0:
				on_dialogue_start.call()
			1:
				on_dialogue_start.call(instance)
			_:
				push_error("on_dialogue_start expects too many arguments.")

static func hide_dialogue() -> void:
	var finished_type := dialogue_type
	dialogue_playing = false
	dialogue_type = ""
	instance.visible = false
	instance.emit_signal("dialogue_finished", finished_type)

func _process(_delta: float) -> void:
	if not dialogue_playing:
		return

	var line = lines[dialogue_type]

	if Input.is_action_just_pressed("ui_confirm"):
		current_line += 1
		if current_line >= line.size():
			hide_dialogue()
			PlayerStates.general_mode.switch("Idle")
		else:
			update_label(line[current_line])
