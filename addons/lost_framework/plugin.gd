@tool
extends EditorPlugin

const _REMOTE_ENABLED := "lost_framework/asset_manager/remote_enabled"
const _BASE_URL := "lost_framework/asset_manager/base_url"


func _enter_tree() -> void:
	_ensure_setting(_REMOTE_ENABLED, TYPE_BOOL, false)
	_ensure_setting(_BASE_URL, TYPE_STRING, "")


func _exit_tree() -> void:
	pass


func _ensure_setting(setting_name: String, setting_type: int, default_value: Variant) -> void:
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, default_value)
	ProjectSettings.add_property_info({
		"name": setting_name,
		"type": setting_type,
	})
	ProjectSettings.set_initial_value(setting_name, default_value)
	ProjectSettings.set_as_basic(setting_name, true)
