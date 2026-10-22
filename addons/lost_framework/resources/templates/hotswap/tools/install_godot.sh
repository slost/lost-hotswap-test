#!/usr/bin/env bash
# Install the Godot editor and export templates for a pre-release tag.
#
# Beta and dev builds are published on godotengine/godot-builds, not on
# godotengine/godot. The asset names keep the status string ("4.8-beta1"),
# while the export-template directory uses the editor's own version string
# ("4.8.beta1", dot instead of hyphen). Stable installers do not follow this
# pair of rules, so do not point this script at a godotengine/godot stable URL.
set -euo pipefail

TAG="${GODOT_TAG:-4.8-beta1}"
BASE="https://github.com/godotengine/godot-builds/releases/download/${TAG}"
WORKDIR="${TMPDIR:-/tmp}/godot-install-${TAG}"
mkdir -p "$WORKDIR" "$HOME/.local/godot"

if [ ! -x "$HOME/.local/godot/godot" ]; then
  curl -fL --retry 5 --retry-delay 2 -o "$WORKDIR/editor.zip" \
    "${BASE}/Godot_v${TAG}_linux.x86_64.zip"
  rm -rf "$WORKDIR/editor"
  unzip -o "$WORKDIR/editor.zip" -d "$WORKDIR/editor"
  bin="$(find "$WORKDIR/editor" -type f -name "Godot_v${TAG}_linux*" | head -n 1)"
  if [ -z "$bin" ]; then
    echo "Editor binary not found in ${BASE}/Godot_v${TAG}_linux.x86_64.zip" >&2
    exit 1
  fi
  cp "$bin" "$HOME/.local/godot/godot"
  chmod +x "$HOME/.local/godot/godot"
fi

ver_line="$("$HOME/.local/godot/godot" --version)"
echo "Godot version: ${ver_line}"
case "$ver_line" in
  4.8.beta1.*) ;;
  *)
    echo "Expected a 4.8.beta1 version string, got: ${ver_line}" >&2
    exit 1
    ;;
esac

template_ver="${ver_line%%.official*}"
dest="$HOME/.local/share/godot/export_templates/${template_ver}"
if [ ! -f "${dest}/web_nothreads_release.zip" ]; then
  if [ ! -f "$WORKDIR/templates.tpz" ]; then
    curl -fL --retry 5 --retry-delay 2 -o "$WORKDIR/templates.tpz" \
      "${BASE}/Godot_v${TAG}_export_templates.tpz"
  fi
  rm -rf "$WORKDIR/templates"
  unzip -q "$WORKDIR/templates.tpz" -d "$WORKDIR/templates"
  if [ ! -d "$WORKDIR/templates/templates" ]; then
    echo "Export template archive did not contain a templates/ directory" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mv "$WORKDIR/templates/templates" "$dest"
fi

test -f "${dest}/web_nothreads_release.zip"
test -f "${dest}/web_nothreads_debug.zip"
echo "Export templates: ${dest}"
