extends Node2D

@onready var status_label: Label = $CanvasLayer/UI/Status
@onready var jump_player: AudioStreamPlayer = $JumpSfx


func _ready() -> void:
	$CanvasLayer/UI/PlayJump.pressed.connect(_on_play_jump)
	$CanvasLayer/UI/Reload.pressed.connect(_on_reload)
	AssetManager.status_changed.connect(_refresh_status)
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_on_reload()
		get_viewport().set_input_as_handled()


func _on_play_jump() -> void:
	jump_player.play()


func _on_reload() -> void:
	AssetManager.reload()


func _refresh_status() -> void:
	status_label.text = AssetManager.status_text()
	AssetManager.write_dom()
