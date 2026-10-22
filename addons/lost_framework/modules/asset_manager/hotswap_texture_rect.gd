extends TextureRect

@export var asset_id: String = ""


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	AssetManager.bind(self)


func apply_hotswap(source: String, remote_texture: Variant, _remote_audio: Variant) -> void:
	if source == "remote" and remote_texture is Texture2D:
		texture = remote_texture
	else:
		texture = AssetManager.placeholder_texture(asset_id)
