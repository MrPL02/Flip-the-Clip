extends Window

const DEFAULT_CODE = "var string:String = \"hello world!\"\n\nfunc _ready():\n\tprint(string)"

@onready var drag_label:Label = $DragLabel
@onready var tab_cont:TabContainer = $TabContainer

@onready var tag_edit:TextEdit = $TabContainer/File/TagEdit
@onready var microgame_name:LineEdit = $TabContainer/File/LineEdit
@onready var option_button:OptionButton = $TabContainer/File/OptionButton
@onready var save_button:Button = $TabContainer/File/ButtonSave
@onready var hint_edit:LineEdit = $TabContainer/File/HintEdit

@onready var texture_list:ItemList = $TabContainer/Images/ItemList

@onready var sound_list:ItemList = $TabContainer/Sounds/ItemList

@onready var code_edit:CodeEdit = $TabContainer/Code/CodeEdit

@onready var file_buttons:Control = $FileButtons
@onready var erase_button:Button = $FileButtons/EraseButton
@onready var rename_button:Button = $FileButtons/RenameButton
@onready var rename_edit:LineEdit = $FileButtons/LineEdit

@onready var debug_label:RichTextLabel = $TabContainer/Debug

@onready var test_scene:SubViewportContainer = SubViewportContainer.new()

var microgame:Node = null
var texture_data:Dictionary = {}
var sound_data:Dictionary = {}
var selected_tab:String = ""


func _ready():
	save_button.pressed.connect(save_microgame)
	$TabContainer/File/ButtonTest.pressed.connect(test_microgame)
	$TabContainer/File/ButtonLoad.pressed.connect(load_microgame)
#	$TabContainer/Debug/UpdateButton.pressed.connect(update_debug)
	$FileButtons/RenameButton.pressed.connect(request_rename_data)
	$FileButtons/EraseButton.pressed.connect(request_erase_data)
	texture_list.item_selected.connect(item_selected)
	sound_list.item_selected.connect(item_selected)
	files_dropped.connect(_on_files_dropped)
	position = DisplayServer.screen_get_size()/2
	
	test_scene.size = Game.WINDOW_SIZE_DEFAULT
	get_parent().add_child.call_deferred(test_scene)

func _notification(what):
	if what == 1006:
		set_process(false)
		if is_instance_valid(microgame):
			microgame.queue_free()
		test_scene.queue_free()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Note: sound_data and texture_ara only contains AudioStreamMP3 and Image data.
func _on_files_dropped(files:PackedStringArray):
	print(files)
	for file in files:
		
		if file.ends_with(".png"):
			var n = file.get_file().replace(".png","")
			if texture_data.has(n): OS.alert("The file "+file.get_file()+" will not be added because\nthere's already a file with the same name.","Warning!")
			else:
				var image = Image.load_from_file(file)
				var texture = ImageTexture.create_from_image(image)
				texture_list.add_item(n, texture)
				texture_data[n] = image.data
			
		if file.ends_with(".mp3"):
#			var sound = AudioStreamMP3.new()
#			sound.data = fa.get_buffer(fa.get_length())
			var n = file.get_file().replace(".mp3","")
			if sound_data.has(n): OS.alert("The file "+file.get_file()+" will not be added because\nthere's already a file with the same name.","Warning!")
			else:
				var fa = FileAccess.open(file, FileAccess.READ)
				sound_list.add_item(n)
				sound_data[n] = fa.get_buffer(fa.get_length())
		
	texture_list.sort_items_by_text()
	sound_list.sort_items_by_text()

func get_data() -> Dictionary:
	var dict = {
		"textures" : texture_data,
		"sounds" : sound_data,
		"script" : code_edit.text,
		"control" : option_button.selected,
		"hint" : hint_edit.text,
		"tags" : tag_edit.text,
	}
	return dict

# MICROGAME FILE SYSTEM: (V = Done)
#V script (String, Multiline) The microgame code writen on GDScript.
#V textures (Dictonary) List of used textures data.
#V sounds (Dictonary) List of used AudioStreams data.
#V control (int) Type of control on the microgame.
#V hint (String) Hint about the microgame goal.
#V tags (PackedStringArray) Used to separate microgames.

# win() -> void - Setting did_win to True with a SFX. Has no effect if lose() has been called frist
# lose() -> void - Setting did_win to False with a SFX. Has no effect if win() has been called frist.

# VARIABLES MICROGAME
# time_left (int, defaults to 5) Time left on the microgame on beats. If is -1 the microgame will never end. The ingame timer only uptades each beat.
# did_win (bool, defaults to False) If the player did actually win. If you don't want the player to wait set time_left to 0.

func save_microgame() -> void:
	if save_button.disabled: return
	
	var file_name:String = microgame_name.text+".mgame"
	var file = FileAccess.open_compressed("user://microgames/"+file_name,FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD)
	if file == null: push_error("Error with saving it lol. Error code: %d."%FileAccess.get_open_error())
	else:
		var data:Dictionary = get_data()
		file.store_var(data)
		print("File %s saved!"%file_name)

func load_microgame() -> void:
	var file_name:String = microgame_name.text+".mgame"
	var file = FileAccess.open_compressed("user://microgames/"+file_name,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	if FileAccess.file_exists("user://microgames/"+file_name):
		var data = file.get_var()
		nuke_file()
		for i in data:
			match i:
				"textures":
					texture_data = data[i]
					for y in texture_data:
						var image = Image.new()
						image.data = texture_data[y]
						texture_list.add_item(y,ImageTexture.create_from_image(image))
					texture_list.sort_items_by_text()
				"sounds":
					sound_data = data[i]
					for y in sound_data:
						sound_list.add_item(y)
					sound_list.sort_items_by_text()
				"script":
					code_edit.text = data[i]
				"control":
					option_button.selected = data[i]
				"hint":
					hint_edit.text = data[i]
				"tags":
					tag_edit.text = data[i]

func test_microgame() -> void:
	save_microgame()
	for i in test_scene.get_children(): i.queue_free()
	await get_tree().process_frame
	var scene = Game.create_microgame_scene(get_data())
	debug_label.clear()
	scene.print_db.connect(debug_label.append_text)
	microgame = scene
	
	# You need to do this to a subviewport container because otherwise it glitches and only shows up godot logo.
	test_scene.set_visible(false)
	test_scene.add_child(scene)
	test_scene.set_visible(true)
	
#	test_scene.get_tree().root.request_attention()

func _process(_delta):
	save_button.disabled = !microgame_name.text.is_valid_filename()
	selected_tab = tab_cont.get_tab_title(tab_cont.current_tab)
	if not selected_tab == "Images": texture_list.deselect_all()
	if not selected_tab == "Sounds": sound_list.deselect_all()
	file_buttons.visible = selected_tab in ["Images", "Sounds"]
	rename_button.disabled = !allowed_name(rename_edit.text)
	drag_label.visible = false
	
	match selected_tab:
		"Images":
			drag_label.text = "Drag .png files here\nto add textures!"
			drag_label.visible = texture_data.size()==0
			
			for i in file_buttons.get_children():
				var disabled:bool = texture_list.get_selected_items().size()==0
				i.visible = !disabled
		"Sounds":
			drag_label.text = "Drag .mp3 files here\nto add sounds!"
			drag_label.visible = sound_data.size()==0
			
			for i in file_buttons.get_children():
				var disabled:bool = sound_list.get_selected_items().size()==0
				i.visible = !disabled

func item_selected(index:int) -> void:
	match selected_tab:
		"Images":
			rename_edit.text = texture_list.get_item_text(index)
		"Sounds":
			rename_edit.text = sound_list.get_item_text(index)

func request_erase_data() -> void:
	match selected_tab:
		"Images":
			var items:PackedInt32Array = texture_list.get_selected_items()
			if  items!=PackedInt32Array([]):
				for i in items:
					texture_data.erase(texture_list.get_item_text(i))
					texture_list.remove_item(i)
		"Sounds":
			var items:PackedInt32Array = sound_list.get_selected_items()
			if items!=PackedInt32Array([]):
				for i in items:
					sound_data.erase(sound_list.get_item_text(i))
					sound_list.remove_item(i)

func request_rename_data() -> void:
	var new_name:String = rename_edit.text
	match selected_tab:
		"Images":
			var items:PackedInt32Array = texture_list.get_selected_items()
			if texture_data.has(new_name): OS.alert("A file already owns that name!")
			elif items!=PackedInt32Array([]):
				var item:int = items[0]
				var old_name:String = texture_list.get_item_text(item)
				
				texture_list.add_item(new_name, texture_list.get_item_icon(item))
				texture_list.remove_item(item)
				texture_list.sort_items_by_text()
				
				texture_data[new_name] = texture_data[old_name]
				texture_data.erase(old_name)
		
		"Sounds":
			var items:PackedInt32Array = sound_list.get_selected_items()
			if texture_data.has(new_name): OS.alert("A file already owns that name!")
			elif items!=PackedInt32Array([]):
				var item:int = items[0]
				var old_name:String = sound_list.get_item_text(item)
				
				sound_list.add_item(new_name, sound_list.get_item_icon(item))
				sound_list.remove_item(item)
				sound_list.sort_items_by_text()
				
				sound_data[new_name] = sound_data[old_name]
				sound_data.erase(old_name)

func allowed_name(n:String) -> bool:
	return n.length() > 0 and n.length() < 256

func nuke_file() -> void:
	code_edit.text = DEFAULT_CODE
	texture_list.clear()
	sound_list.clear()
	texture_data = {}
	sound_data = {}
