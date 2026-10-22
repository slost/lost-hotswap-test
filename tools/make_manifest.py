#!/usr/bin/env python3
"""Build the hot-swap manifest and the assets/status.html page.

Reads assets/expected_ids.txt. Each non-comment line is "<id> <texture|audio>".
A texture id expects assets/<id>.png. An audio id expects assets/<id>.ogg.
Missing files stay in the manifest with present=false so the game can show
a placeholder. The Pages workflow copies the result into the published site.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import html
import json
import shutil
from pathlib import Path


TYPES = {
    "texture": ".png",
    "audio": ".ogg",
}


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def read_expected(path: Path) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) != 2 or parts[1] not in TYPES:
            raise SystemExit(
                f"{path}:{line_number}: expected '<id> texture' or '<id> audio', got {raw!r}"
            )
        rows.append((parts[0], parts[1]))
    if not rows:
        raise SystemExit(f"{path} did not list any asset ids")
    return rows


def build_entries(assets_dir: Path, rows: list[tuple[str, str]]) -> list[dict]:
    entries: list[dict] = []
    for asset_id, asset_type in rows:
        file_name = asset_id + TYPES[asset_type]
        file_path = assets_dir / file_name
        entry: dict = {
            "id": asset_id,
            "type": asset_type,
            "file": file_name,
            "present": file_path.is_file(),
        }
        if file_path.is_file():
            data = file_path.read_bytes()
            entry["sha256"] = hashlib.sha256(data).hexdigest()
            entry["bytes"] = len(data)
        else:
            entry["sha256"] = None
            entry["bytes"] = 0
        entries.append(entry)
    return entries


def status_page(entries: list[dict], generated_at: str) -> str:
    body_rows = []
    for entry in entries:
        state = "present" if entry["present"] else "missing"
        digest = entry["sha256"] or "—"
        size = str(entry["bytes"]) if entry["present"] else "—"
        if entry["present"]:
            link = f'<a href="{html.escape(entry["file"])}">{html.escape(entry["file"])}</a>'
        else:
            link = "—"
        body_rows.append(
            "<tr>"
            f"<td><code>{html.escape(entry['id'])}</code></td>"
            f"<td>{html.escape(entry['type'])}</td>"
            f"<td>{state}</td>"
            f"<td>{size}</td>"
            f"<td><code>{html.escape(digest)}</code></td>"
            f"<td>{link}</td>"
            "</tr>"
        )
    rows_html = "\n".join(body_rows)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hot-swap asset status</title>
<style>
  body {{ font: 16px/1.45 system-ui, sans-serif; margin: 2rem; color: #172026; background: #f6f7f4; }}
  table {{ border-collapse: collapse; background: white; }}
  th, td {{ border: 1px solid #d5dbd6; padding: 0.4rem 0.7rem; text-align: left; vertical-align: top; }}
  th {{ background: #e7eee8; }}
  code {{ font-family: ui-monospace, monospace; }}
  .missing {{ color: #8a3b12; }}
</style>
</head>
<body>
<h1>Hot-swap asset status</h1>
<p>Generated {html.escape(generated_at)}. Drop <code>&lt;id&gt;.png</code> or <code>&lt;id&gt;.ogg</code> into <code>assets/</code> and push to <code>main</code>. A commit that only touches <code>assets/</code> republishes this page without a Godot export.</p>
<p>สถานะไฟล์ hot-swap สร้างเมื่อ {html.escape(generated_at)}. วางไฟล์ชื่อ <code>&lt;id&gt;.png</code> หรือ <code>&lt;id&gt;.ogg</code> ลงใน <code>assets/</code> แล้ว push ขึ้น <code>main</code>. ถ้าคอมมิตแก้เฉพาะใน <code>assets/</code> หน้านี้จะถูกเผยแพร่ใหม่โดยไม่เอ็กซ์พอร์ต Godot</p>
<table>
<thead>
<tr><th>id</th><th>type</th><th>state</th><th>bytes</th><th>sha256</th><th>file</th></tr>
</thead>
<tbody>
{rows_html}
</tbody>
</table>
</body>
</html>
"""


def write_outputs(root: Path, site: Path | None) -> list[dict]:
    assets_dir = root / "assets"
    rows = read_expected(assets_dir / "expected_ids.txt")
    entries = build_entries(assets_dir, rows)
    generated_at = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    manifest = {
        "format": 1,
        "generated_at": generated_at,
        "assets": entries,
    }
    text = json.dumps(manifest, indent=2) + "\n"
    page = status_page(entries, generated_at)
    (root / "manifest.json").write_text(text, encoding="utf-8")
    (assets_dir / "status.html").write_text(page, encoding="utf-8")
    if site is not None:
        site.mkdir(parents=True, exist_ok=True)
        (site / "manifest.json").write_text(text, encoding="utf-8")
        published = site / "assets"
        if published.exists():
            shutil.rmtree(published)
        published.mkdir()
        for entry in entries:
            if not entry["present"]:
                continue
            shutil.copy2(assets_dir / entry["file"], published / entry["file"])
        shutil.copy2(assets_dir / "expected_ids.txt", published / "expected_ids.txt")
        (published / "status.html").write_text(page, encoding="utf-8")
    return entries


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=project_root())
    parser.add_argument(
        "--site",
        type=Path,
        default=None,
        help="Also write manifest.json and assets/ into this published directory.",
    )
    args = parser.parse_args()
    entries = write_outputs(args.root.resolve(), args.site.resolve() if args.site else None)
    present = sum(1 for entry in entries if entry["present"])
    print(f"manifest: {present}/{len(entries)} files present")
    for entry in entries:
        state = "present" if entry["present"] else "MISSING"
        print(f"  {entry['id']}: {state}")


if __name__ == "__main__":
    main()
