extends Node2D


func _ready():
	$VersionLabel.text = Game.VER_TEXT
	$PMenuButton1.pressed.connect(_on_game_start)
	$PMenuButton2.pressed.connect(_on_free_start)
	$PMenuButton3.pressed.connect(_on_mod_start)

func _on_game_start():
	get_tree().change_scene_to_file("res://scenes/playstate.tscn")

func _on_free_start():
	get_tree().change_scene_to_file("res://scenes/freeplay.tscn")
	
func _on_mod_start():
	get_tree().change_scene_to_file("res://scenes/microgame_maker.tscn")
