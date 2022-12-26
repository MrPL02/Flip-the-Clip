extends Node2D

@onready var back:Sprite2D = $Back

var time:float = 0.0

func _ready():
	Game.reload_microgames()
	$VersionLabel.text = Game.VER_TEXT
	$PMenuButton1.pressed.connect(_on_game_start)
	$PMenuButton2.pressed.connect(_on_free_start)
	$PMenuButton3.pressed.connect(_on_mod_start)

func _process(delta):
	time += delta
	back.region_rect.position = Vector2(time/2,sin(time)*3)*10

func _on_game_start():
	get_tree().change_scene_to_file("res://scenes/playstate.tscn")

func _on_free_start():
	get_tree().change_scene_to_file("res://scenes/freeplay.tscn")
	
func _on_mod_start():
	get_tree().change_scene_to_file("res://scenes/microgame_maker.tscn")
