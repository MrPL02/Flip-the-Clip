extends Control

@onready var item_list:ItemList = $ItemList
@onready var hint_label:Label = $HintLabel

var data:Array = []
var data_name:Array = []


func _ready():
	Game.reload_microgames()
	$BackButton.pressed.connect(go_back)
	$StartButton.pressed.connect(_start_pratice)
	for i in Game.microgames_data:
		var index:int = 0
		for j in Game.microgames_data[i]:
			data.append(i+"|"+str(index))
			data_name.append(j.name)
			index += 1
	hint_label.text = ""
	print(data)
	print(data_name)
	
	for i in data_name: item_list.add_item(i)

func _process(_delta):
	for i in item_list.get_selected_items():
		var id:Array = data[i].split("|")
		id[1] = int(id[1])
		var n_data:Dictionary = Game.microgames_data[id[0]][id[1]]
		hint_label.text = n_data.hint

func _start_pratice():
	var selected:Array = item_list.get_selected_items()
	if selected.size() > 0:
		var i = selected[0]
		var id:Array = data[i].split("|")
		id[1] = int(id[1])
		print("FUNNY START PRATICE")
		var playstate = load("res://scenes/playstate.tscn").instantiate()
		playstate.data_micro = Game.microgames_data[id[0]][id[1]]
		playstate.freeplay = true
		get_parent().add_child(playstate)
		visible = false
#		item_list.deselect_all()

func go_back(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
