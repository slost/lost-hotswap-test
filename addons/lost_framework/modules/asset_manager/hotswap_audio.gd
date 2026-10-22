extends AudioStreamPlayer

@export var asset_id: String = ""
@export var loop_stream: bool = false
@export var play_on_ready: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	AssetManager.bind(self)


func apply_hotswap(source: String, _remote_texture: Variant, remote_audio: Variant) -> void:
	var was_playing := playing
	var next: AudioStream = null
	if source == "remote" and remote_audio is AudioStream:
		next = remote_audio
		if next is AudioStreamOggVorbis and loop_stream:
			(next as AudioStreamOggVorbis).loop = true
	else:
		next = AssetManager.placeholder_audio(loop_stream)
	stream = next
	if play_on_ready or was_playing:
		play()
