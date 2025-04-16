class_name Doors

static var is_opened = false
static var is_labeled = false

static func is_door(result: Dictionary) -> bool:
	if result.collider.get_parent() and result.collider.get_parent().name.find("$DOOR$") != -1:
		return true
	return false

static func label_door(label: Label) -> void:
	is_labeled = true
	label.text = "Press [E] to interact"

static func unlabel_door(label: Label) -> void:
	is_labeled = false
	label.text = ""

static func open_door(animation_player: AnimationPlayer) -> void:
	if not animation_player.is_playing():
		if is_opened:
			animation_player.play("door_close")
			is_opened = false
		else:
			animation_player.play("door_open")
			is_opened = true
