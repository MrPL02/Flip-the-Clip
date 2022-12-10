extends CanvasLayer

@onready var play_state = get_parent()

var paused:bool = false


func _ready():
	$PMenuButton1.pressed.connect(continue_game)
	$PMenuButton2.pressed.connect(end_game)

func _process(_delta):
	paused = get_tree().paused
	visible = paused
	if Input.is_action_just_pressed("ui_cancel") and play_state.state != play_state.States.GAME_OVER:
		get_tree().paused = !paused

func continue_game():
	get_tree().paused = false

func end_game():
	continue_game()
	play_state.set_state(play_state.States.GAME_OVER)
