# Hot-swap assets

Remote art and audio ship as plain files next to the web export. The Godot
package keeps a generated placeholder for every id. When remote mode is on,
`AssetManager` downloads `manifest.json` and replaces each placeholder whose
file is actually present.

This copy of the addon documents the contract used by the `lost-hotswap-test`
project. The draft branch `cursor/hotswap-asset-manager-7ed0` in
`slost/lost-ecosystem` was not readable from the environment that assembled
this repo (GitHub returns 404), so there is no upstream commit SHA to pin.

## Project settings

Both settings are opt-in. Remote loading stays off until a game turns it on.

| Setting | Type | Meaning |
| --- | --- | --- |
| `lost_framework/asset_manager/remote_enabled` | bool | Download the manifest on boot. |
| `lost_framework/asset_manager/base_url` | String | Site root with no trailing slash. Manifest URL is `<base_url>/manifest.json`. Files are `<base_url>/assets/<file>`. |

On a web export, `?assets=off` forces placeholders even when remote mode is enabled. `?base=<url>` overrides `base_url` for that page load (used to point a local export at a local web server).

`AssetManager.reload()` fetches the manifest again. The demo binds it to the Reload button and the R key.

## Nodes

| Node | Base | Exported property |
| --- | --- | --- |
| `HotSwapSprite` | `Sprite2D` | `asset_id` |
| `HotSwapTextureRect` | `TextureRect` | `asset_id` |
| `HotSwapAudio` | `AudioStreamPlayer` | `asset_id`, `loop_stream`, `play_on_ready` |

Each node calls `AssetManager.bind(self)` and receives `apply_hotswap(source, texture, audio)`. `source` is `remote` or `placeholder`.

The ids this demo knows are `tex_player`, `ui_logo`, `bgm_menu`, and `sfx_jump`. A web build also mirrors the same lines into a DOM node `#hotswap-status`, because the in-game label is drawn on the canvas.

## Manifest

`tools/make_manifest.py` reads `assets/expected_ids.txt` and writes `manifest.json`.

```json
{
  "format": 1,
  "generated_at": "2026-10-22T00:00:00Z",
  "assets": [
    {"id": "tex_player", "type": "texture", "file": "tex_player.png", "present": true, "sha256": "...", "bytes": 1234},
    {"id": "ui_logo", "type": "texture", "file": "ui_logo.png", "present": false, "sha256": null, "bytes": 0}
  ]
}
```

`assets/<id>.png` is a texture. `assets/<id>.ogg` is audio. A listed id with no file stays `present: false` and the game keeps the placeholder. The same script writes `assets/status.html`.

The drop folder contains `.gdignore` so Godot does not import those files into the pck. The Web preset also sets `exclude_filter="assets/*,manifest.json"` and `variant/thread_support=false` (GitHub Pages does not send the cross-origin-isolation headers a threaded web build requires). `build/.gdignore` keeps the export output from being imported back into the project.

## Install the template into a game repo

Template path: `addons/lost_framework/resources/templates/hotswap/`.

1. Copy `tools/` to the game repo `tools/`.
2. Copy `assets/` (the `expected_ids.txt` list and `.gdignore`) to the game repo `assets/`.
3. Copy `.github/workflows/pages.yml` to the game repo.
4. Copy `export_presets.cfg` if the game does not already export Web. Keep thread support off. Add an empty `build/.gdignore` so the export output is not imported.
5. Enable the Lost Framework plugin. In Project Settings turn on `lost_framework/asset_manager/remote_enabled` and set `base_url` to the GitHub Pages origin, with no trailing slash.
6. Add `HotSwapSprite`, `HotSwapTextureRect`, and `HotSwapAudio` nodes whose `asset_id` values match `expected_ids.txt`.
7. Put real files in `assets/` for the ids that should leave the placeholder. Commit and push to `main`.

## Pages workflow

`.github/workflows/pages.yml` deploys from `main`.

* **Full path.** Install Godot `4.8-beta1` from `godotengine/godot-builds` (editor zip plus `Godot_v4.8-beta1_export_templates.tpz`). The template directory is `4.8.beta1`, taken from `godot --version`, not from the hyphenated tag. Export the Web preset, upload the shell as the `web-shell` artifact, then overlay `manifest.json` and `assets/`.
* **Fast path.** If every file in the push is under `assets/`, download the `web-shell` artifact from the last successful run and skip the Godot install and export. The log line is `FAST PATH: skipping Godot export`. A missing artifact falls back to a full export.

GitHub Pages must use Source = GitHub Actions.
