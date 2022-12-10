extends SubViewport

@onready var camera:Camera2D = Camera2D.new()
@onready var canvas:CanvasLayer = preload("res://scenes/canvas_micro.tscn").instantiate()
@onready var bomb_icon:Sprite2D = canvas.get_node("BombSprite")
@onready var bomb_meter:Sprite2D = canvas.get_node("BombSprite/Meter")
@onready var bomb_fire:Sprite2D = canvas.get_node("BombSprite/Fire")
@onready var bomb_expl:Sprite2D = canvas.get_node("BombSprite/Kaboom")

var microgame_data:Dictionary = {}

var ended:bool = false
var did_won:bool = false
var has_time_limit:bool = true
var beat_time_limit:int = 16
var visual_extend:float = 16
var bpm:float = 120

var prev_beat:int = 0
var internal_beat:int = 0
var internal_time:float = 0
var visual_beat:float = 10
var check_time_limit:bool = true

func _internal_ready():
	camera.current = true
#	bomb_meter.offset.x = 0.5
#	bomb_meter.position = Vector2(17.5,7.5)
#	bomb_icon.position = Vector2(8.5,176)
#	bomb_icon.z_index = 10
	add_child(camera)
	add_child(canvas)
#	canvas.add_child(bomb_icon)
#	bomb_icon.add_child(bomb_meter)
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

func win() -> void:
	did_won = true
	end_early()

func lose() -> void:
	did_won = false
	end_early()

func end_early(offset:int=1) -> void:
	check_time_limit = false
	if not has_time_limit:
		has_time_limit = true
		bomb_icon.visible = false
	if beat_time_limit-internal_beat > offset:
		internal_time = Game.calc_spb(bpm)*(beat_time_limit-offset)

func get_image(id:String) -> Image:
	if microgame_data.has("textures"):
		if microgame_data.textures.has(id):
			var img:Image = Image.new()
			img.data = microgame_data["textures"][id]
			return img
	return null

func get_sound(id:String, s_bpm:float=120.0) -> AudioStreamMP3:
	if microgame_data.has("sounds"):
		if microgame_data.sounds.has(id):
			var sound:AudioStreamMP3 = AudioStreamMP3.new()
			sound.data = microgame_data["sounds"][id]
			sound.loop = false
			sound.bpm = s_bpm
			return sound
	return null

#################
# CUSTOM SCRIPT #
