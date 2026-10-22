extends Node2D

const WATCHED: PackedStringArray = ["tex_player", "ui_logo", "bgm_menu", "sfx_jump"]

@onready var status_label: Label = $CanvasLayer/UI/Status
@onready var jump_player: AudioStreamPlayer = $JumpSfx

var _connected := false
var _dom_reload_callback: JavaScriptObject


func _ready() -> void:
	$CanvasLayer/UI/PlayJump.pressed.connect(_on_play_jump)
	$CanvasLayer/UI/Reload.pressed.connect(_on_reload)
	_connect_manager()
	_refresh_status()


func _connect_manager() -> void:
	if Assets.manager == null:
		call_deferred("_connect_manager")
		return
	if _connected:
		return
	_connected = true
	Assets.manager.asset_updated.connect(_refresh_status)
	Assets.manager.manifest_loaded.connect(_on_manifest_loaded)
	Assets.manager.all_loaded.connect(_refresh_status)
	_refresh_status()
	_install_dom_hooks()


func _on_manifest_loaded(_ok: bool) -> void:
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_on_reload()
		get_viewport().set_input_as_handled()


func _on_play_jump() -> void:
	jump_player.play()


func _on_reload() -> void:
	if Assets.manager:
		Assets.manager.reload()
	_refresh_status()


func _refresh_status(_id: String = "") -> void:
	if status_label == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	var remote_on := Assets.manager != null and Assets.manager.base_url != ""
	lines.append("mode: %s" % ("remote" if remote_on else "off"))
	for id in WATCHED:
		var state := "placeholder" if Assets.is_placeholder(id) else "remote"
		var detail := ""
		if id.begins_with("tex_") or id.begins_with("ui_"):
			var tex := Assets.fetch_texture(id)
			if tex:
				detail = " %dx%d" % [tex.get_width(), tex.get_height()]
		lines.append("%s: %s%s" % [id, state, detail])
	status_label.text = "\n".join(lines)
	_write_dom(status_label.text)


func _write_dom(text: String) -> void:
	if not OS.has_feature("web"):
		return
	var script := "(function(text){var node=document.getElementById('hotswap-status');if(!node){node=document.createElement('pre');node.id='hotswap-status';node.style.cssText='position:fixed;left:0;bottom:0;margin:0;padding:8px;background:#111;color:#9f9;font:14px/1.4 monospace;z-index:10;white-space:pre';document.body.appendChild(node);}node.textContent=text;})(%s)" % JSON.stringify(text)
	JavaScriptBridge.eval(script, true)


## The page button calls the same reload path as the on-screen Reload button and the R key.
func _install_dom_hooks() -> void:
	if not OS.has_feature("web"):
		return
	var window := JavaScriptBridge.get_interface("window")
	# Keep the callback alive. Godot frees it if only JavaScript holds it.
	_dom_reload_callback = JavaScriptBridge.create_callback(_on_dom_reload)
	window.__lostDemoReload = _dom_reload_callback
	JavaScriptBridge.eval("""
		(function () {
			if (document.getElementById('hotswap-reload')) {
				return;
			}
			var button = document.createElement('button');
			button.id = 'hotswap-reload';
			button.type = 'button';
			button.textContent = 'Reload (R)';
			button.style.cssText = 'position:fixed;right:8px;bottom:8px;z-index:11';
			button.addEventListener('click', function () {
				if (window.__lostDemoReload) {
					window.__lostDemoReload();
				}
			});
			document.body.appendChild(button);
		})()
	""", true)


func _on_dom_reload(_args: Array) -> void:
	_on_reload()
