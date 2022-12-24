extends Node

const WINDOW_SIZE_DEFAULT = Vector2i(256,192)
const MICROGAMES_FOLDERS = ["res://microgames","user://microgames"]
const VER_TEXT = "PRE-ALPHA v0.1.5"

@onready var window:Window = get_viewport()
@onready var base_script = preload("res://scripts/base_microgame.gd")


var window_position:Vector2 = Vector2.ZERO
var microgames_data:Dictionary = {}
var microgames:Array = []
var audio_created:Array = [[],[]]
var int_time:int = 0

func _ready():
	print("Add this on a splash screen:\n")
	print("THIS GAME ALLOWS MODDING!\nTHE FINAL USER IS THE SOLE RESPONSIBLE OF ANY EFFECTS MODS MAY CAUSE.\n\nAlso this game is open sorce!\nGAMEJOLT IS THE ONLY PLATFORM WITH OFFICIAL RELASES AND GITHUB THE ONLY CONTANING THE SORCE CODE.\nUSING ANY OTHER SIZE MAY RISK GETTING MALWARE OR WORSE; A CAR EXTENDED WARRANTY.\n\ntl;dr Don't download shit kiddos.\nABOUT COPYRIGHTED CONTENT\nFLIPWARE EXPECTS THAT THE MODDERS (The mods creators) TO HOLD THE COPYRIGHT OF ANY ASSET.\nTHE MODDER IS LIABLE OF ANY DAMAGE IT MAY CAUSE BY USING STOLEN COPYRIGHT CONTENT.\nBY CREATING INGAME MODIFICATIONS YOU AGREE THAT YOUR MODS DOESN'T BREAK ANY COPYRIGHT OR CYBERNETIC LAW.\n")
	
	if DisplayServer.screen_get_size() > WINDOW_SIZE_DEFAULT*3:
		window.size = WINDOW_SIZE_DEFAULT*2
		window.position -= WINDOW_SIZE_DEFAULT/2
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("microgames"): dir.make_dir("microgames")

func _input(event):
	if event is InputEventKey:
		if not event.echo and event.pressed and event.keycode in [KEY_ASCIITILDE,KEY_BRACKETLEFT]:
			print("funni debug")

func _process(delta):
	int_time += 1
	window_position = Vector2(window.position)/Vector2(DisplayServer.screen_get_size()-window.size/2)
	for i in microgames:
		if is_instance_valid(i):
			if i.has_method("_internal_process") and i.is_inside_tree():
				i._internal_process(delta)
		else: microgames.erase(i)

	for i in audio_created[0]:
		if is_instance_valid(i):
			if i.get_playback_position() == i.stream.get_length() or not i.playing:
				audio_created[0].erase(i)
				audio_created[1].append(i)
				print("Stopped Audio "+str(i.name)+".")
		else:
			audio_created[0].erase(i)
			print("Removed invalid audio.")

func reload_microgames() -> void:
	microgames_data = {}
	print("reloading microgames")
	for i in MICROGAMES_FOLDERS:
		microgames_data[i] = []
		var files:PackedStringArray = DirAccess.get_files_at(i)
		var index:int = 0
		for j in files:
			if not j.ends_with(".mgame"): continue
			print(i+"/"+j)
			var file = FileAccess.open_compressed(i+"/"+j, FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
			if file.get_error() == OK:
				microgames_data[i].append(file.get_var())
				microgames_data[i][index]["name"] = j.replace(".mgame","").capitalize()
			index += 1

func create_audio(file:AudioStream,volume_db:float=0.0,pitch:float=1.0) -> void:
	var audio
#	var is_2d:bool = position==Vector2.ZERO
	var reuse_id = audio_created[1].size()-1
	var can_reuse = reuse_id>-1
	if can_reuse:
		audio = audio_created[1][reuse_id]#audio_created[1][int(is_2d)][reuse_id]
		audio_created[1].remove_at(reuse_id)
#	elif is_2d:
	else:
		audio = AudioStreamPlayer.new()
#	else:
#		audio = AudioStreamPlayer2D.new()
	audio.stream = file
	audio.pitch_scale = pitch
	audio.volume_db = volume_db
	audio_created[0].append(audio)
	if can_reuse:
		print("Reused Audio "+str(audio.name)+".")
	else:
		add_child(audio)
		print("Created Audio "+str(audio.name)+".")
	audio.play()

func create_microgame_scene(data:Dictionary) -> Node:
	var game = SubViewport.new()
	game.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST 
	game.canvas_item_default_texture_repeat = true
	if data.has("script"):
		var new_script:GDScript = GDScript.new()
		new_script.source_code = base_script.source_code+data.script
		print(new_script.source_code)
		var err = new_script.reload(true)
		if err == OK:
			game.set_script(new_script)
			game.microgame_data = data
			game.call_deferred("_internal_ready")
			microgames.append(game)
		else:
			var label = Label.new()
			label.text = "err"+str(err)
			game.call_deferred("add_child",label)
	game.size = WINDOW_SIZE_DEFAULT
	return game

func calc_beat(calc_time:float, calc_bpm:float, calc_pitch:float=Engine.time_scale) -> int:
	calc_bpm *= calc_pitch
	var scp:float = 60.0/calc_bpm
	return int(floor(calc_time/scp))

func calc_spb(calc_bpm:float, calc_pitch:float=Engine.time_scale) -> float:
	calc_bpm *= calc_pitch
	return 60.0/calc_bpm

