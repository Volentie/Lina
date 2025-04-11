class_name PlayerStates

# States
static var general_mode = StateMachine.new("GeneralMode", {
	"Intro": State.new("Intro"),
	"Walking": State.new("Walking"),
	"Running": State.new("Running"),
	"Jumping": State.new("Jumping"),
	"Idle": State.new("Idle"),
	"Air": State.new("Air")
})

static var speed_mode = StateMachine.new("SpeedMode", {
	"Run": State.new("Run", func(): PlayerConfig.speed = PlayerConfig.run_speed),
	"Walk": State.new("Walk", func(): PlayerConfig.speed = PlayerConfig.walk_speed),
})

static var camera_mode = StateMachine.new("CameraMode", {
	"Player": State.new("Player"),
	"Object": State.new("Object")
})
