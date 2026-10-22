# Lost hot-swap test

End-to-end test of the Lost framework hot-swap asset pipeline on GitHub Pages.

Play the build: <https://slost.github.io/lost-hotswap-test/>

Asset status: <https://slost.github.io/lost-hotswap-test/assets/status.html>

Godot version: **4.8-beta1** (`godot --version` reports `4.8.beta1.official.4d10419ca`). Editor and export templates are downloaded from [godotengine/godot-builds](https://github.com/godotengine/godot-builds/releases/tag/4.8-beta1). Pre-release files are not on `godotengine/godot`, and the template directory uses `4.8.beta1` (a dot, not the hyphen in the tag).

## English

### What is in this repo

A minimal Godot 4.8-beta project with the Lost Framework addon enabled. Remote mode is on. `lost_framework/asset_manager/base_url` is the Pages URL above. The design notes live in `addons/lost_framework/modules/asset_manager/HOTSWAP.md`. The game-repo template is installed from `addons/lost_framework/resources/templates/hotswap/` (`tools/make_manifest.py`, `tools/install_godot.sh`, `assets/expected_ids.txt`, the Pages workflow, and a Web export preset with thread support off).

The draft PR <https://github.com/slost/lost-ecosystem/pull/19> (branch `cursor/hotswap-asset-manager-7ed0`) was not readable from the environment that built this test. The GitHub API returns 404 for `slost/lost-ecosystem`, and this agent's credentials only include `slost/lost-hotswap-test`. There is no upstream commit SHA to record, and framework fixes could not be pushed back to that branch. The addon in this repo is the hot-swap contract described for that PR: the remote-manifest overlay, `HotSwapSprite`, `HotSwapTextureRect`, `HotSwapAudio`, and the Pages template.

### How to upload a file

1. Pick an id from `assets/expected_ids.txt`.
2. Save the file in `assets/` using that id as the name: `assets/<id>.png` for a texture, or `assets/<id>.ogg` for audio. Do not rename the extension.
3. Commit and push to `main`. A push that only adds or changes files under `assets/` republishes the site without running Godot. Any other change exports the web build again.
4. An id with no file is intentional. The game draws a placeholder for it. This repo starts with `ui_logo` missing so that placeholder stays visible.

The `assets/` folder is marked with `.gdignore`, so Godot does not bake those files into the game package. Players download them from the manifest after the page loads.

### How to view status

Open <https://slost.github.io/lost-hotswap-test/assets/status.html>. The table lists every expected id, whether the file is present, and its sha256. The game itself is at <https://slost.github.io/lost-hotswap-test/>. The on-screen label (and the text box at the bottom of the page) shows each id as `remote` or `placeholder`. Add `?assets=off` to the game URL to keep every id on its placeholder.

Buttons: **Play sfx_jump** plays the jump sound, **Reload (R)** calls `AssetManager.reload()` and fetches the manifest again.

## ภาษาไทย

โปรเจกต์นี้ใช้ทดสอบระบบสลับไฟล์เกม (hot-swap) ของเฟรมเวิร์ก Lost บน GitHub Pages จริง

เปิดเกม: <https://slost.github.io/lost-hotswap-test/>

หน้าสถานะไฟล์: <https://slost.github.io/lost-hotswap-test/assets/status.html>

เวอร์ชัน Godot คือ **4.8-beta1** (สตริงเวอร์ชันจากตัวเอดิเตอร์คือ `4.8.beta1`) ดาวน์โหลดจาก `godotengine/godot-builds` เพราะไฟล์เบต้าไม่อยู่ที่รีโป stable และโฟลเดอร์เทมเพลตใช้จุด (`4.8.beta1`) ไม่ใช่ขีดในชื่อแท็ก

แอดออนในรีโปนี้ทำตามสัญญาที่อธิบายไว้ใน PR #19 ของ `slost/lost-ecosystem` สาขา `cursor/hotswap-asset-manager-7ed0` สภาพแวดล้อมที่ใช้สร้างรีโปทดสอบเข้าถึงรีโปนั้นไม่ได้ (GitHub ตอบ 404) จึงไม่มี SHA ของคอมมิตต้นทางให้บันทึก และส่งการแก้กลับไปที่สาขานั้นไม่ได้ รายละเอียดอยู่ใน `addons/lost_framework/modules/asset_manager/HOTSWAP.md`

### วิธีอัปโหลดไฟล์

1. เลือก id จาก `assets/expected_ids.txt`
2. วางไฟล์ลงในโฟลเดอร์ `assets/` โดยใช้ id เป็นชื่อไฟล์: รูปคือ `assets/<id>.png` เสียงคือ `assets/<id>.ogg` ห้ามเปลี่ยนนามสกุล
3. คอมมิตแล้ว push ขึ้นสาขา `main` ถ้าคอมมิตนั้นแก้เฉพาะไฟล์ใน `assets/` เวิร์กโฟลว์จะเผยแพร่ไซต์ใหม่โดยไม่เอ็กซ์พอร์ต Godot ถ้ามีไฟล์อื่นเปลี่ยนด้วย จะเอ็กซ์พอร์ตเว็บใหม่ทั้งก้อน
4. id ที่ยังไม่มีไฟล์เป็นของที่ตั้งใจเว้นไว้ เกมจะแสดงภาพหรือเสียงสำรอง (placeholder) รีโปนี้เริ่มต้นโดยยังไม่ใส่ไฟล์ของ `ui_logo` เพื่อให้เห็น placeholder บนจอ

โฟลเดอร์ `assets/` มีไฟล์ `.gdignore` เพื่อไม่ให้ Godot ฝังไฟล์เหล่านี้ลงในแพ็กเกจเกม ผู้เล่นจะดาวน์โหลดจาก manifest หลังเปิดหน้าเว็บ

### วิธีดูหน้าสถานะ

เปิด <https://slost.github.io/lost-hotswap-test/assets/status.html> จะเห็นตารางของทุก id ว่ามีไฟล์แล้วหรือยัง พร้อมค่า sha256 ตัวเกมอยู่ที่ <https://slost.github.io/lost-hotswap-test/> ป้ายข้อความบนจอ (และกล่องข้อความมุมล่างของหน้าเว็บ) บอกแต่ละ id ว่าเป็น `remote` หรือ `placeholder` ถ้าต้องการบังคับให้ทุก id เป็น placeholder ให้เปิดเกมพร้อม `?assets=off`

ปุ่ม **Play sfx_jump** เล่นเสียงกระโดด ปุ่ม **Reload (R)** เรียก `AssetManager.reload()` แล้วดึง manifest ใหม่
