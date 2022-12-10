extends Node2D
enum States {
# IMPORTANT STATES #
	STARTING, 	# Game starting and being setup. Only gets called once.
	READY,		# A microgame has been selected and is about to be played.
	PLAYING, 	# The microgame is being played. The microgame will only run on this state.
	MICRO_END,	# The microgame is ending.
	LOSE, 		# The microgame is over with a L.
	WIN,  		# The microgame is over with a W.
	GAME_OVER,	# The game has been ended. It can end even if the player still has some lifes left.
	WARN_SPEED, # The warning that the BPM is increasing.
#	WARN_BOSS, 	# The warning that the next microgame is a BOSS microgame.
	NONE=-1,	# Placeholder State
	
# Non important States #
	CUSTOM_TEST, # Example of a custom state. It doesn't do anything but is here.
}

const OVERWRTITE_STATES = [ # States that doesn't call on_music_end EVER.
	States.PLAYING,
	States.GAME_OVER,
	States.NONE,
] 

@onready var info_label:Label = $InfoLabel
@onready var anim_play:AnimationPlayer = $AnimationPlayer
@onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer
@onready var micro_container:SubViewportContainer = $Things/SubViewportContainer
@onready var tip_label:RichTextLabel = $TipTextLabel

@export_range(1, 999) var rounds_per_speed_up:int = 6
@export var speed_increase:float = 0.05

var data_micro:Dictionary = {}
var microgame_scene:SubViewport = null
var freeplay:bool = false
var score:int = 0
var lifes:int = 4

var state:int = States.NONE

var did_won:bool = false
var must_speed_up:bool = false
var times_speed_up:int = 0


func _ready():
#	MusicManager.on_end.connect(on_music_end)
#	audio_player.finished.connect(on_state_end)
	anim_play.animation_finished.connect(on_state_end)
	set_state(States.STARTING)
	Engine.time_scale = 1.0
	if freeplay:
		rounds_per_speed_up = 1


func _process(_delta):
	micro_container.process_mode = Node.PROCESS_MODE_INHERIT if state == States.PLAYING else Node.PROCESS_MODE_DISABLED
	info_label.text = "Speed: x%f\nScore: %d\nLifes: %d\nState: %d"%[Engine.time_scale,score,lifes,state]
	audio_player.pitch_scale = Engine.time_scale
#	anim_play.playback_speed = Game.speed_scale
#	if freeplay: times_speed_up = 0
	match state:
		States.PLAYING:
			if microgame_scene.ended:
				set_state(States.MICRO_END)


func on_state_end(_a):
	if state in OVERWRTITE_STATES: return
	print("end state ",state)
	
	match state:
		States.READY:
			set_state(States.PLAYING)
		States.MICRO_END:
			if is_instance_valid(microgame_scene): microgame_scene.queue_free()
			set_state(States.WIN if did_won else States.LOSE)
		_:
			set_state(States.GAME_OVER if lifes == 0 else States.WARN_SPEED if must_speed_up else States.READY)

# I know this is ulgy, this function takes all microgames all only leaves those that include and exclude a specific set of tags.
func get_microgames(filter:PackedStringArray=PackedStringArray([]), exclude:PackedStringArray=PackedStringArray(["boss"])) -> Array:
	var mg:Array = []
	for i in Game.microgames_data:
		for j in Game.microgames_data[i]:
			var allowed:bool = false
			if filter.size()+exclude.size() == 0: allowed = true
			elif j.has("tags"):
				allowed = true
				for t in j.tags:
					if filter.size() > 0:
						if not t in filter:
							allowed = false
							break
					if exclude.size() > 0:
						if t in exclude:
							allowed = false
							break
			if allowed: mg.append(j)
	return mg

func set_state(id:int) -> void:
#	MusicManager.pitch_scale = 1.7
#	var prev_state:int = state
	state = id
	match id:
		States.STARTING:
			anim_play.play("start")
#			MusicManager.play_music(preload("res://sounds/start_game.ogg"))
#			audio_player.stream = preload("res://sounds/start_game.ogg")
#			audio_player.play()
		
		States.READY:
			if not freeplay:
				var micros = get_microgames()
				data_micro = micros[randi()%micros.size()].duplicate()
			tip_label.text = "[center][shake rate=20 level=4]"+data_micro.hint
			anim_play.play("ready")
			score += 1
		
		States.LOSE:
			lifes -= 1
			anim_play.play("lose")
		
		States.WIN:
			anim_play.play("win")
		
		States.WARN_SPEED:
			Engine.time_scale += speed_increase
			must_speed_up = false
			if freeplay: set_state(States.READY)
			else:
				times_speed_up += 1
				anim_play.play("warn_speed")
		
		States.GAME_OVER:
			print("THAT'S ALL FOLKS!")
			anim_play.stop(false)
			Engine.time_scale = 1.0
			if is_instance_valid(microgame_scene):
				microgame_scene.queue_free()
				$Things/StaticRect.visible = true
#			MusicManager.play_music(preload("res://sounds/game_over.ogg"))
			audio_player.stream = preload("res://sounds/game_over.ogg")
			audio_player.play()
		
		States.PLAYING:
			print("starting microgame")
			microgame_scene = Game.create_microgame_scene(data_micro)
			anim_play.play("start_micro")
			
			# You need to do this to a subviewport container because otherwise it glitches and only shows up godot logo.
			micro_container.set_visible(false)
			micro_container.add_child(microgame_scene)
			micro_container.set_visible(true)
		
		States.MICRO_END:
			did_won = microgame_scene.did_won
			must_speed_up = (score%rounds_per_speed_up)==0
			anim_play.play("end_micro")
		
		_:
#			MusicManager.play_music(preload("res://sounds/test.ogg"))
			audio_player.stream = preload("res://sounds/test.ogg")
			audio_player.play()

func get_state() -> int: return state
