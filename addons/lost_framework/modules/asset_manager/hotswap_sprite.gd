extends Sprite2D

@export var asset_id: String = ""


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	AssetManager.bind(self)


func apply_hotswap(source: String, remote_texture: Variant, _remote_audio: Variant) -> void:
	if source == "remote" and remote_texture is Texture2D:
		texture = remote_texture
	else:
		texture = AssetManager.placeholder_texture(asset_id)
