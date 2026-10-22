# Lost hot-swap test

End-to-end test of the Lost framework hot-swap asset pipeline on GitHub Pages.

Play the build: <https://slost.github.io/lost-hotswap-test/>

Asset status: <https://slost.github.io/lost-hotswap-test/assets/status.html>

Manifest: <https://slost.github.io/lost-hotswap-test/assets/manifest.json>

Godot version: **4.8-beta1** (`godot --version` reports `4.8.beta1.official.4d10419ca`). Editor and export templates come from [godotengine/godot-builds](https://github.com/godotengine/godot-builds/releases/tag/4.8-beta1). The template folder is `4.8.beta1` (a dot, not the hyphen in the tag). The Web export preset keeps thread support off.

## English

### What is in this repo

A minimal Godot 4.8-beta project. The addon under `addons/lost_framework/` is the Lost framework from `slost/lost-ecosystem` commit `6c34a2adf7efafdb8f38eb098197ce87fd3e1022`. Design notes are in `addons/lost_framework/modules/asset_manager/HOTSWAP.md`.

Lost loads modules from `res://lost/assigned_modules.json`. This demo activates `asset_manager` and `audio_manager`. Autoloads, in order, are Refs, Rng, SignalBus, Lost, Audio, SaveManager, and Settings. There is no Asset autoload. Remote mode is on. `lost_framework/asset_manager/base_url` is `assets/`, which the web build resolves against the page URL.

The demo scene uses `HotSwapSprite` (`tex_player`), `HotSwapTextureRect` (`ui_logo`), and `HotSwapAudio` (`bgm_menu` looping once the remote file arrives, plus `sfx_jump`). The on-screen label reads `Assets.is_placeholder` and the texture size. **Play sfx_jump** plays the jump stream. **Reload (R)** calls `Assets.manager.reload()`.

One vendored script is patched so this project can boot. See the report on `settings.module.gd`: it referenced a `Game` autoload that does not exist here, and Godot 4.8-beta1 refused to parse the script.

### How to upload a file

1. Pick an id from `assets/expected_ids.txt` (one id per line).
2. Save the file in `assets/` as `assets/<id>.png` (or webp/jpg) or `assets/<id>.ogg` (or mp3/wav). The id is the file name without the extension, lowercased.
3. Commit and push to `main`. The Pages workflow caches the web export with a hash of every file outside `assets/`. A push that only changes `assets/` reuses that export and does not run Godot. Any other change exports again.
4. An id with no file stays on the built-in placeholder (magenta checkerboard or beep).

The `assets/` folder has `.gdignore`, and the Web preset excludes `assets/` and `tools/`, so those files are not packed into the game. The workflow writes `assets/manifest.json` and `assets/status.html` on the site. `bgm_` files are marked `"loop": true`.

### How to view status

Open <https://slost.github.io/lost-hotswap-test/assets/status.html>. The game is at <https://slost.github.io/lost-hotswap-test/>. Add `?assets=off` to keep every id on its placeholder. The label at the bottom of the page mirrors the in-game status, including texture size, so a reload can show that a new file arrived.

## ภาษาไทย

โปรเจกต์นี้ใช้ทดสอบระบบสลับไฟล์เกม (hot-swap) ของเฟรมเวิร์ก Lost บน GitHub Pages จริง

เปิดเกม: <https://slost.github.io/lost-hotswap-test/>

หน้าสถานะไฟล์: <https://slost.github.io/lost-hotswap-test/assets/status.html>

manifest: <https://slost.github.io/lost-hotswap-test/assets/manifest.json>

เวอร์ชัน Godot คือ **4.8-beta1** ดาวน์โหลดจาก `godotengine/godot-builds` โฟลเดอร์เทมเพลตใช้จุด (`4.8.beta1`) พรีเซ็ตเว็บปิด thread support

แอดออนใน `addons/lost_framework/` คือเฟรมเวิร์ก Lost จากคอมมิต `6c34a2adf7efafdb8f38eb098197ce87fd3e1022` ของ `slost/lost-ecosystem` รายละเอียดอยู่ใน `addons/lost_framework/modules/asset_manager/HOTSWAP.md`

Lost โหลดโมดูลจาก `res://lost/assigned_modules.json` เดโมนี้เปิด `asset_manager` กับ `audio_manager` ออโตโหลดเรียงเป็น Refs, Rng, SignalBus, Lost, Audio, SaveManager, Settings ไม่มีออโตโหลดชื่อ Asset โหมดรีโมตเปิดอยู่ และ `base_url` คือ `assets/` ซึ่งบนเว็บจะต่อท้ายที่อยู่ของหน้าเกม

ฉากเดโมใช้ `HotSwapSprite` (`tex_player`), `HotSwapTextureRect` (`ui_logo`) และ `HotSwapAudio` (`bgm_menu` จะวนเมื่อไฟล์รีโมตมาถึง และ `sfx_jump`) ป้ายบนจออ่านจาก `Assets.is_placeholder` พร้อมขนาดรูป ปุ่ม **Play sfx_jump** เล่นเสียงกระโดด ปุ่ม **Reload (R)** เรียก `Assets.manager.reload()`

มีจุดที่แก้ในแอดออนที่คัดลอกมาหนึ่งไฟล์ เพื่อให้โปรเจกต์บูตได้: `settings.module.gd` อ้างออโตโหลดชื่อ `Game` ที่โปรเจกต์นี้ไม่มี และ Godot 4.8-beta1 แปลสคริปต์ไม่ผ่าน

### วิธีอัปโหลดไฟล์

1. เลือก id จาก `assets/expected_ids.txt` (หนึ่ง id ต่อหนึ่งบรรทัด)
2. วางไฟล์ในโฟลเดอร์ `assets/` ชื่อ `assets/<id>.png` (หรือ webp/jpg) หรือ `assets/<id>.ogg` (หรือ mp3/wav) id คือชื่อไฟล์ไม่รวมนามสกุล และเป็นตัวพิมพ์เล็ก
3. คอมมิตแล้ว push ขึ้น `main` เวิร์กโฟลว์แคชไฟล์เว็บจากแฮชของทุกไฟล์นอก `assets/` ถ้าคอมมิตแก้เฉพาะใน `assets/` จะใช้แคชนั้นและไม่รัน Godot ถ้ามีไฟล์อื่นเปลี่ยน จะเอ็กซ์พอร์ตใหม่
4. id ที่ยังไม่มีไฟล์จะค้างที่ placeholder (ตารางหมากรุกสีม่วง หรือเสียงบี๊บ)

โฟลเดอร์ `assets/` มี `.gdignore` และพรีเซ็ตเว็บไม่แพ็ก `assets/` กับ `tools/` เวิร์กโฟลว์สร้าง `assets/manifest.json` และ `assets/status.html` บนไซต์ ไฟล์ที่ขึ้นต้นด้วย `bgm_` จะได้ `"loop": true`

### วิธีดูหน้าสถานะ

เปิด <https://slost.github.io/lost-hotswap-test/assets/status.html> ตัวเกมอยู่ที่ <https://slost.github.io/lost-hotswap-test/> ถ้าต้องการบังคับให้ทุก id เป็น placeholder ให้เปิดเกมพร้อม `?assets=off` ป้ายมุมล่างของหน้าเว็บสะท้อนข้อความในเกม รวมถึงขนาดรูป เพื่อให้กด Reload แล้วเห็นว่าไฟล์ใหม่มาถึง
