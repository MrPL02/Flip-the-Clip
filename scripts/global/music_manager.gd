extends AudioStreamPlayer
signal on_beat(id_beat)
signal on_end()

var bpm:float = 150.0
var true_bpm:float = 150.0
var measures = 52
var beat_offset = 0
# Each beat is 4 measures.

var last_beat = 0
var sec_per_beat = 60.0
var song_position = 0.0
var song_beat = 0
var global_beat = 0
var measure = 0
var beats = 0

var ended:bool = false
var in_beat:bool = false

var song_name:String = ""



func _process(_delta):
#	volume_db = linear_to_db(Game.data.options.audio.instrumental_volume)
	if playing:
		ended = false
		bpm = true_bpm*pitch_scale
		beats = ceil(stream.get_length()/bpm)
		measures = beats*4
		sec_per_beat = 60.0/bpm
		song_position = get_playback_position() + AudioServer.get_time_since_last_mix()
		song_position -= AudioServer.get_output_latency()
		song_beat = int(floor(song_position/sec_per_beat)) + beat_offset
		_report_beat()
	elif not ended:
		ended = true
		emit_signal("on_end")

func _report_beat() -> void:
	in_beat = last_beat==song_beat
	if not in_beat:
		if measure > measures:
			measure = measures
		global_beat += song_beat-last_beat
		last_beat = song_beat
		measure += 1
		emit_signal("on_beat",int(global_beat))#int(last_beat))
		if stream.beat_count > 0 and song_beat > stream.beat_count:
			if stream.loop: play_music(stream)
			else: playing = false

func play_music(music:AudioStreamOggVorbis,from:float=music.loop_offset) -> void:
	beat_offset = 0
	song_beat = 1
	global_beat = 1
	measure = 0
	ended = false
	
	stream = music
	play(from)
	set_bpm(music.bpm)
#	emit_signal("beat",0)

func calc_beat(calc_time:float, calc_bpm:float, pitch:float=1.0) -> int:
	calc_bpm *= pitch
	var scp:float = 60.0/calc_bpm
	return int(floor(calc_time/scp))

func calc_spb(calc_bpm:float, pitch:float=1.0) -> float:
	calc_bpm *= pitch
	return 60.0/calc_bpm

func set_bpm(bpm_amount:float) -> void:
	true_bpm = bpm_amount
	bpm = true_bpm*pitch_scale
	beats = ceil(stream.get_length()/bpm)
	measures = beats*4
	sec_per_beat = 60.0/bpm
	song_beat = int(floor(song_position/sec_per_beat))+beat_offset
	last_beat = max(0,song_beat-1)

func get_bpm() -> float: return bpm
