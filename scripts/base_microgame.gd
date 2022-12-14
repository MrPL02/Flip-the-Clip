extends SubViewport

## This signal gets send if print is used.
signal print_db(msg:String)

## I HAVE A SEVERE CASE OF DIARRHEA
## AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

#@onready var camera:Camera2D = Camera2D.new()

## Canvas containing the bomb and stuff. The scene containing the canvas is "res://scenes/canvas_micro.tscn".
@onready var canvas:CanvasLayer = preload("res://scenes/canvas_micro.tscn").instantiate()
## The node BombSprite from the canvas.
@onready var bomb_icon:Sprite2D = canvas.get_node("BombSprite")
## The node BombSprite/Meter from the canvas.
@onready var bomb_meter:Sprite2D = canvas.get_node("BombSprite/Meter")
## The node BombSprite/Fire from the canvas.
@onready var bomb_fire:Sprite2D = canvas.get_node("BombSprite/Fire")
## The node BombSprite/Kaboom from the canvas.
@onready var bomb_expl:Sprite2D = canvas.get_node("BombSprite/Kaboom")

## The data from the microgame file.
var microgame_data:Dictionary = {}

## If the microgame ended. [br][br]
## [color=yellow]Warning:[/color][br]To avoid errors, once it is True, it cannot become False again.
var ended:bool = false:
	get:
		return ended
	set(value):
		if !ended: ended = value
		else: push_warning("The microgame has ended and it cannot restart. This is not an error.")

## If the microgame will be considered as "won" when it ends.
var did_won:bool = false
## If it has a time limit.
var has_time_limit:bool = true
## The time limit mesured in beats. Will be ignored if [member has_time_limit] is false.
var beat_time_limit:int = 16
## The size of each beat on the timer.
var visual_extend:float = 16
## The BPM of the microgame. Will NOT be ignored if [member has_time_limit] is false.
var bpm:float = 120

var prev_beat:int = 0
var internal_beat:int = 0
var internal_time:float = 0
var visual_beat:float = 10
var check_time_limit:bool = true

func _internal_ready():
	add_child(canvas)
	canvas.show()

func _internal_process(delta:float):
	internal_time += delta
	internal_beat = Game.calc_beat(internal_time,bpm)
	if check_time_limit:
		bomb_icon.visible = has_time_limit
	
	var previsual_beat:float = beat_time_limit-internal_beat-1
	visual_beat = (previsual_beat)+visual_beat/1.7
	bomb_icon.position.y = (bomb_icon.position.y-176)/1.1+176
	bomb_meter.scale.x = max(0,visual_beat)*visual_extend+1
	bomb_fire.position.x = bomb_meter.scale.x+23.5
	bomb_fire.frame = int(Game.int_time%10<5)
	bomb_expl.visible = visual_beat<0
	
	if has_method("_process"): set_process(!ended)
	if has_method("_physics_process"): set_physics_process(!ended)
	if has_method("_input"): set_process_input(!ended)
	if not ended:
		if not prev_beat == internal_beat and has_time_limit:
			prev_beat = internal_beat
			ended = beat_time_limit-internal_beat<0
			if beat_time_limit-internal_beat < 4 and check_time_limit and not ended:
				if beat_time_limit-internal_beat == 0: pass
				else: Game.create_audio(preload("res://sounds/bomb_tick.ogg"))

###################
# MAKER FUNCTIONS #

## Sets [member did_won] to True and calls [method end_early].
func win() -> void:
	debug_print("WIN")
	did_won = true
	end_early()

## Sets [member did_won] to False and calls [method end_early].
func lose() -> void:
	debug_print("LOSE")
	did_won = false
	end_early()

## Sets the microgame timer to end early by [code]offset[/code] beats.
func end_early(offset:int=1) -> void:
	check_time_limit = false
	if not has_time_limit:
		has_time_limit = true
		bomb_icon.visible = false
	if beat_time_limit-internal_beat > offset:
		internal_time = Game.calc_spb(bpm)*(beat_time_limit-offset)

## Returns the image file on the microgame data.
## [br]Returns [code]null[/code] if it doesn't exist.
func get_image(id:String) -> Image:
	if microgame_data.has("textures"):
		if microgame_data.textures.has(id):
			var img:Image = Image.new()
			img.data = microgame_data["textures"][id]
			return img
	return null

## Returns the sound file on the microgame data.
## [br]Returns [code]null[/code] if it doesn't exist.
func get_sound(id:String, s_bpm:float=120.0) -> AudioStreamMP3:
	if microgame_data.has("sounds"):
		if microgame_data.sounds.has(id):
			var sound:AudioStreamMP3 = AudioStreamMP3.new()
			sound.data = microgame_data["sounds"][id]
			sound.loop = false
			sound.bpm = s_bpm
			return sound
	return null

## Prints on the debug tab.
func debug_print(msg=null) -> void:
	if not msg is String: msg = str(msg)
	msg = "[%.3fs] %s\n"%[internal_time, msg]
	emit_signal("print_db",msg)
	printraw(msg)

#################
# CUSTOM SCRIPT #
