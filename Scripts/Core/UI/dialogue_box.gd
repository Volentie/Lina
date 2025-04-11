extends Control

signal dialogue_finished

var lines := [
	"Lina...?",
	"Where are you?",
	"You mean so much to me.",
	"You can't just vanish like that!"
]

var current_line := 0
@onready var label := $Label

func _ready() -> void:
	update_line()

func update_line() -> void:
	if current_line < lines.size():
		label.text = lines[current_line]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_confirm"):
		current_line += 1
		if current_line >= lines.size():
			emit_signal("dialogue_finished") # Signalze to player.gd to process input
			queue_free() # Remove the dialogue box at the end of the current frame
		else:
			update_line()
