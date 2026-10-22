extends Node

## Remote-manifest overlay for hot-swapped textures and audio.
##
## Project settings (opt-in):
##   lost_framework/asset_manager/remote_enabled
##   lost_framework/asset_manager/base_url
##
## On the web export, "?assets=off" keeps every id on its placeholder.
## "?base=<url>" overrides base_url for a single page load.

signal status_changed

const IDS: PackedStringArray = ["tex_player", "ui_logo", "bgm_menu", "sfx_jump"]

var _sources: Dictionary = {}
var _textures: Dictionary = {}
var _audios: Dictionary = {}
var _placeholder_textures: Dictionary = {}
var _placeholder_audio_loop: AudioStream
var _placeholder_audio_oneshot: AudioStream
var _nodes: Array[Node] = []
var _generation := 0
var _mode := "off"
var _web_jobs: Array[Dictionary] = []


func _ready() -> void:
	set_process(false)
	for id in IDS:
		_sources[id] = "placeholder"
	if _remote_allowed():
		_mode = "remote"
		_begin_fetch()
	else:
		_mode = "off"
		_publish()


func source_of(id: String) -> String:
	return str(_sources.get(id, "placeholder"))


func mode() -> String:
	return _mode


func status_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("mode: %s" % _mode)
	for id in IDS:
		lines.append("%s: %s" % [id, source_of(id)])
	return "\n".join(lines)


func bind(node: Node) -> void:
	if node not in _nodes:
		_nodes.append(node)
	_apply_to(node)


func reload() -> void:
	for id in IDS:
		_sources[id] = "placeholder"
	_textures.clear()
	_audios.clear()
	for node in _nodes:
		_apply_to(node)
	if _remote_allowed():
		_mode = "remote"
		_begin_fetch()
	else:
		_generation += 1
		_mode = "off"
		_publish()


func placeholder_texture(asset_id: String) -> Texture2D:
	if _placeholder_textures.has(asset_id):
		return _placeholder_textures[asset_id]
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var hash := asset_id.hash()
	var stripe := Color.from_hsv(float(hash % 360) / 360.0, 0.55, 0.85)
	var gap := Color(0.12, 0.12, 0.14, 1.0)
	for y in image.get_height():
		for x in image.get_width():
			var band := int((x + y) / 8) % 2
			image.set_pixel(x, y, stripe if band == 0 else gap)
	var texture := ImageTexture.create_from_image(image)
	_placeholder_textures[asset_id] = texture
	return texture


func placeholder_audio(loop_stream: bool) -> AudioStream:
	if loop_stream:
		if _placeholder_audio_loop == null:
			_placeholder_audio_loop = _make_beep(220.0, 0.4, true)
		return _placeholder_audio_loop
	if _placeholder_audio_oneshot == null:
		_placeholder_audio_oneshot = _make_beep(660.0, 0.12, false)
	return _placeholder_audio_oneshot


func _remote_allowed() -> bool:
	if not bool(ProjectSettings.get_setting("lost_framework/asset_manager/remote_enabled", false)):
		return false
	if _query_flag("assets") == "off":
		return false
	return true


func _base_url() -> String:
	var override := _query_flag("base")
	var raw := override
	if raw.is_empty():
		raw = str(ProjectSettings.get_setting("lost_framework/asset_manager/base_url", ""))
	return raw.strip_edges().trim_suffix("/")


func _begin_fetch() -> void:
	_generation += 1
	var gen := _generation
	var base := _base_url()
	if base.is_empty():
		_mode = "remote"
		_publish()
		return
	var stamp := Time.get_unix_time_from_system()
	_http_get("%s/manifest.json?t=%d" % [base, stamp], gen, func(body: PackedByteArray, code: int) -> void:
		if gen != _generation:
			return
		if code != 200:
			push_warning("Hot-swap manifest request failed (%s): %s" % [code, base])
			_publish()
			return
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("Hot-swap manifest was not a JSON object.")
			_publish()
			return
		var assets: Variant = parsed.get("assets", [])
		if typeof(assets) != TYPE_ARRAY:
			_publish()
			return
		_load_entries(assets, 0, gen, base)
	)


func _load_entries(entries: Array, index: int, gen: int, base: String) -> void:
	if gen != _generation:
		return
	if index >= entries.size():
		for node in _nodes:
			_apply_to(node)
		_publish()
		return
	var entry: Variant = entries[index]
	if typeof(entry) != TYPE_DICTIONARY:
		_load_entries(entries, index + 1, gen, base)
		return
	var asset_id := str(entry.get("id", ""))
	var present := bool(entry.get("present", false))
	var file_name := str(entry.get("file", ""))
	var digest := str(entry.get("sha256", ""))
	var asset_type := str(entry.get("type", ""))
	if asset_id.is_empty() or not present or file_name.is_empty() or asset_id not in IDS:
		_load_entries(entries, index + 1, gen, base)
		return
	var url := "%s/assets/%s?v=%s" % [base, file_name.uri_encode(), digest.uri_encode()]
	_http_get(url, gen, func(body: PackedByteArray, code: int) -> void:
		if gen != _generation:
			return
		if code == 200 and body.size() > 0:
			_ingest(asset_id, asset_type, body)
		else:
			push_warning("Hot-swap file missing for %s (%s)" % [asset_id, code])
		_load_entries(entries, index + 1, gen, base)
	)


func _ingest(asset_id: String, asset_type: String, body: PackedByteArray) -> void:
	if asset_type == "texture":
		var image := Image.new()
		if image.load_png_from_buffer(body) != OK:
			push_warning("Hot-swap PNG decode failed for %s" % asset_id)
			return
		_textures[asset_id] = ImageTexture.create_from_image(image)
		_sources[asset_id] = "remote"
	elif asset_type == "audio":
		var stream := AudioStreamOggVorbis.load_from_buffer(body)
		if stream == null:
			push_warning("Hot-swap Ogg decode failed for %s" % asset_id)
			return
		_audios[asset_id] = stream
		_sources[asset_id] = "remote"
	else:
		push_warning("Hot-swap unknown type '%s' for %s" % [asset_type, asset_id])


func _apply_to(node: Node) -> void:
	if not node.has_method("apply_hotswap"):
		return
	var asset_id := str(node.get("asset_id"))
	node.call(
		"apply_hotswap",
		source_of(asset_id),
		_textures.get(asset_id),
		_audios.get(asset_id)
	)


func write_dom() -> void:
	if not OS.has_feature("web"):
		return
	var payload := JSON.stringify(status_text())
	JavaScriptBridge.eval(
		"(function(text){if(!document.body)return;var el=document.getElementById('hotswap-status');if(!el){el=document.createElement('pre');el.id='hotswap-status';el.setAttribute('aria-live','polite');el.style.cssText='position:fixed;left:8px;bottom:8px;z-index:20;margin:0;background:rgba(0,0,0,.78);color:#d8ffe4;font:14px/1.45 ui-monospace,monospace;padding:8px 10px;white-space:pre;pointer-events:none';document.body.appendChild(el);}el.textContent=text;})(%s)" % payload,
		true
	)


func _publish() -> void:
	write_dom()
	status_changed.emit()


func _process(_delta: float) -> void:
	if _web_jobs.is_empty():
		set_process(false)
		return
	# done.call() may queue the next fetch. Take the current batch first so
	# that new job is not dropped when this function finishes.
	var batch: Array[Dictionary] = _web_jobs.duplicate()
	_web_jobs.clear()
	var now := Time.get_ticks_msec()
	var still: Array[Dictionary] = []
	for job in batch:
		var gen := int(job["gen"])
		if gen != _generation:
			continue
		if now - int(job["started"]) > 20000:
			push_warning("Hot-swap web fetch timed out for %s" % job["url"])
			(job["done"] as Callable).call(PackedByteArray(), 0)
			continue
		var raw: Variant = JavaScriptBridge.eval("window.__lostFetchPoll(%d)" % int(job["id"]), true)
		var text := str(raw)
		if text.is_empty() or text == "null" or text == "<null>":
			still.append(job)
			continue
		var split_at := text.find(" ")
		var code := 0
		var body := PackedByteArray()
		if split_at > 0:
			code = text.substr(0, split_at).to_int()
			var encoded := text.substr(split_at + 1)
			if not encoded.is_empty():
				body = Marshalls.base64_to_raw(encoded)
		(job["done"] as Callable).call(body, code)
	still.append_array(_web_jobs)
	_web_jobs = still
	if _web_jobs.is_empty():
		set_process(false)


func _http_get(url: String, gen: int, done: Callable) -> void:
	# Godot 4.8-beta1's HTTPRequest uses HTTPClientWeb, which fails to finish a
	# GitHub Pages response (HTTP/2 through the browser fetch wrapper). The
	# browser returns 200 and the engine reports:
	#   Condition "err != 0 && err != 1" is true. Returning: FAILED
	# then request_completed with a non-success result. Read the bytes with
	# fetch() instead. No custom headers, so the request stays a simple GET.
	if OS.has_feature("web"):
		_http_get_web(url, gen, done)
		return
	var request := HTTPRequest.new()
	request.timeout = 20.0
	request.body_size_limit = 8 * 1024 * 1024
	add_child(request)
	var err := request.request(url)
	if err != OK:
		request.queue_free()
		push_warning("Hot-swap HTTP start failed for %s (%s)" % [url, err])
		done.call(PackedByteArray(), 0)
		return
	request.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		request.queue_free()
		if gen != _generation:
			return
		if result != HTTPRequest.RESULT_SUCCESS:
			done.call(PackedByteArray(), 0)
			return
		done.call(body, code)
	, CONNECT_ONE_SHOT)


func _http_get_web(url: String, gen: int, done: Callable) -> void:
	var script := """
(function (url) {
  if (!window.__lostFetch) {
    window.__lostFetchQueue = [];
    window.__lostFetch = function (target) {
      var id = window.__lostFetchQueue.length;
      window.__lostFetchQueue.push("");
      fetch(target).then(function (response) {
        return response.arrayBuffer().then(function (buffer) {
          var bytes = new Uint8Array(buffer);
          var parts = [];
          var step = 0x8000;
          for (var i = 0; i < bytes.length; i += step) {
            parts.push(String.fromCharCode.apply(null, bytes.subarray(i, i + step)));
          }
          window.__lostFetchQueue[id] = response.status + " " + btoa(parts.join(""));
        });
      }).catch(function () {
        window.__lostFetchQueue[id] = "0 ";
      });
      return id;
    };
    window.__lostFetchPoll = function (id) {
      var item = window.__lostFetchQueue[id];
      return item ? item : "";
    };
  }
  return window.__lostFetch(url);
})(%s)""" % JSON.stringify(url)
	var fetch_id := int(JavaScriptBridge.eval(script, true))
	_web_jobs.append({
		"id": fetch_id,
		"gen": gen,
		"url": url,
		"done": done,
		"started": Time.get_ticks_msec(),
	})
	set_process(true)


func _query_flag(flag_name: String) -> String:
	var query := ""
	if OS.has_feature("web"):
		var raw: Variant = JavaScriptBridge.eval("window.location.search", true)
		query = str(raw)
	else:
		for arg in OS.get_cmdline_user_args():
			var prefix := "--%s=" % flag_name
			if arg.begins_with(prefix):
				return arg.substr(prefix.length())
		return ""
	if query.begins_with("?"):
		query = query.substr(1)
	for part in query.split("&", false):
		var bits := part.split("=", true, 1)
		if bits.size() == 2 and bits[0].uri_decode() == flag_name:
			return bits[1].uri_decode()
	return ""


func _make_beep(frequency: float, seconds: float, loop_stream: bool) -> AudioStreamWAV:
	var mix_rate := 22050
	var count := int(mix_rate * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var envelope := 1.0
		if not loop_stream:
			envelope = 1.0 - float(i) / float(count)
		var sample := sin(TAU * frequency * float(i) / float(mix_rate)) * envelope
		var value := int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xff
		data[i * 2 + 1] = (value >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop_stream else AudioStreamWAV.LOOP_DISABLED
	return wav
