# project-next — Dokumentasi Arsitektur

> Action-Adventure Zelda-like game dibangun di **Godot 4.7** (GDScript, renderer GL Compatibility).

---

## 1. Ringkasan Proyek

| Item                      | Nilai                                  |
| ------------------------- | -------------------------------------- |
| Nama proyek               | `project-next`                         |
| Deskripsi (project.godot) | "Action Adventure Zelda-like game"     |
| Engine                    | Godot 4.7, renderer `gl_compatibility` |
| Bahasa                    | GDScript, GDShader                     |
| Resolusi viewport         | 640×360, stretch mode `canvas_items`   |
| Window                    | Borderless                             |
| Main scene                | `Scenes/area_test.tscn`                |

Proyek ini adalah game top-down 2D bergaya Zelda klasik: pemain bergerak 4-arah, menyerang dengan pedang, bisa dash, punya health, dan berinteraksi dengan musuh/dummy serta hazard (spike). Arsitekturnya memakai dua pola utama: **Component Pattern** dan **Finite State Machine (FSM)**, ditambah satu **Autoload Singleton** untuk mengunci aksi pemain secara global.

---

## 2. Project Settings Penting

**Autoload (Singleton)**

```
PlayerActionManager → res://Scripts/Managers/PlayerActionManager.gd
```

Diakses secara global lewat nama `PlayerActionManager` dari script manapun tanpa perlu reference eksplisit.

**Input Map (custom actions, di luar `ui_*` bawaan)**
| Action | Keyboard | Gamepad |
|---|---|---|
| `attack` | X | Joypad button 2 |
| `dash` | Shift (physical keycode 4194326) | Joypad button 0 |

Gerakan (`ui_left/right/up/down`) memakai input action bawaan Godot.

**Physics Layers**

```
Layer 1 = "Player"
Layer 2 = "Props"
```

**Global Groups**

```
Hitable, Player
```

Dipakai untuk menyaring node mana yang boleh menerima damage dan membedakan hitbox milik player vs musuh.

**Rendering**: `gl_compatibility` (baik desktop maupun mobile) — pilihan umum untuk pixel-art 2D agar kompatibel di banyak device.

---

## 3. Struktur Folder

```
project-next/
├── project.godot
├── icon.svg / icon.png
├── sssss.gdshader              # shader efek "echo/scrolling" (lihat §9)
├── Assets/
│   ├── Characters/Player/      # spritesheet player
│   ├── Entity/                 # spritesheet dummy/musuh
│   ├── Tilesets/                # tileset + tile_set.tres
│   └── UIs/                    # aset tombol UI
├── Scenes/
│   ├── area_test.tscn          # ⭐ MAIN SCENE — level test dengan tilemap
│   ├── propechy.tscn           # scene showcase shader "sssss"
│   ├── Character/
│   │   ├── player.tscn         # scene pemain
│   │   └── dummy.tscn          # scene target latihan/musuh dasar
│   ├── Obstacles/
│   │   └── spikes.tscn         # hazard area
│   └── UI/
│       └── button.tscn         # tombol UI generik
├── Scripts/
│   ├── Components/             # komponen reusable (composition pattern)
│   │   ├── animation_player.gd
│   │   ├── damage_component.gd
│   │   ├── heatlh_component.gd     # (typo: "heatlh" bukan "health")
│   │   ├── hitbox_component.gd
│   │   ├── state.gd
│   │   ├── state_mechine.gd        # (typo: "mechine" bukan "machine")
│   │   ├── velocity_component.gd
│   │   ├── dummy/
│   │   │   └── dummy_velocity.gd
│   │   └── player/
│   │       ├── input_component.gd
│   │       ├── player.gd
│   │       ├── player_attack.gd    # State: Attack
│   │       ├── player_dash.gd      # State: Dash
│   │       ├── player_idle.gd      # State: Idle
│   │       ├── player_move.gd      # State: Move
│   │       └── player_velocity.gd
│   ├── Entity/Dummy/
│   │   └── dummy.gd
│   ├── Managers/
│   │   └── PlayerActionManager.gd  # Autoload
│   └── Tiles/
│       └── hazard_area.gd
├── Shaders/
│   └── flash_hit.gdshader      # efek "kena hit" (flash putih)
└── addons/
    └── discord-rpc-gd/          # addon pihak ketiga — Discord Rich Presence
```

---

## 4. Pola Arsitektur

### 4.1 Component Pattern

Setiap entity (`Player`, `Dummy`) adalah `CharacterBody2D` yang **tidak** menaruh semua logic di satu script. Sebaliknya, logic dipecah jadi node anak yang masing-masing punya tanggung jawab tunggal (single responsibility), lalu di-_wire_ lewat `@export` NodePath di editor:

```
CharacterBody2D  (mis. Player / Dummy)
 ├── HealthComponent      → HP, damage, heal, flash-hit
 ├── HitboxComponent       → Area2D penerima serangan
 ├── VelocityComponent     → gerakan & arah (base class)
 ├── InputComponent        → (khusus Player) baca input
 └── StateMachine           → (khusus Player) FSM state
```

Keuntungan pola ini: `Dummy` dan `Player` bisa berbagi `HealthComponent` dan `HitboxComponent` yang identik, sementara `VelocityComponent` di-_extend_ berbeda (`player_velocity.gd` vs `dummy_velocity.gd`) sesuai kebutuhan masing-masing entity.

### 4.2 Finite State Machine (FSM)

Khusus Player, pergerakan/animasi diatur lewat FSM generik (`state_mechine.gd` + `state.gd`) yang state konkretnya adalah node anak bertipe `State`:

```
StateMachine
 ├── Idle    (player_idle.gd)
 ├── Move    (player_move.gd)
 ├── Attack  (player_attack.gd)
 └── Dash    (player_dash.gd)
```

Transisi terjadi lewat signal `Transitioned(state, new_state_name)` yang di-emit oleh state aktif, ditangkap oleh `StateMachine.on_child_transition()`, yang mencari state baru di dictionary `states` (key = nama node huruf kecil) lalu memanggil `exit()` pada state lama dan `enter()` pada state baru.

### 4.3 Autoload Singleton — Global Action Lock

`PlayerActionManager` adalah satu-satunya singleton di proyek ini. Fungsinya sebagai **cooldown/lock gate** supaya input attack & dash tidak bisa di-spam melebihi durasi animasi, dan sebagai penyimpan `attack_state` (combo counter 1↔4) lintas-frame tanpa harus disimpan di state Attack itu sendiri (karena state di-_enter/exit_ ulang tiap kali attack).

---

## 5. Referensi Class & Script

### 5.1 `Scripts/Components/state.gd`

```gdscript
class_name State extends Node
```

Base class abstrak untuk semua state FSM.

| Export var           | Tipe              | Keterangan                                   |
| -------------------- | ----------------- | -------------------------------------------- |
| `body`               | CharacterBody2D   | reference ke entity pemilik                  |
| `state_machine`      | StateMachine      | reference ke FSM induk                       |
| `animation_player`   | AnimationPlayer   | untuk memicu animasi                         |
| `velocity_component` | VelocityComponent | untuk gerak                                  |
| `input`              | InputComponent    | opsional, hanya diisi jika state butuh input |

| Signal                                | Keterangan                       |
| ------------------------------------- | -------------------------------- |
| `Transitioned(state, new_state_name)` | Di-emit untuk minta pindah state |

| Method (virtual, override di subclass) | Dipanggil dari                                      |
| -------------------------------------- | --------------------------------------------------- |
| `enter()`                              | `StateMachine` saat state jadi aktif                |
| `update(delta)`                        | `StateMachine._process()` tiap frame                |
| `physics_update(delta)`                | `StateMachine._physics_process()` tiap physics tick |
| `exit()`                               | `StateMachine` saat state ditinggalkan              |

### 5.2 `Scripts/Components/state_mechine.gd`

```gdscript
class_name StateMachine extends Node
```

| Export var             | Keterangan                    |
| ---------------------- | ----------------------------- |
| `initial_state: State` | state pertama saat `_ready()` |
| `current_state: State` | state aktif saat ini          |

| Method                                       | Deskripsi                                                                                                                                                                                                  |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `_ready()`                                   | Mengumpulkan semua node anak bertipe `State` ke dictionary `states` (key = `name.to_lower()`), connect signal `Transitioned` masing-masing ke `on_child_transition`, lalu jalankan `initial_state.enter()` |
| `_process(delta)`                            | Forward ke `current_state.update(delta)`                                                                                                                                                                   |
| `_physics_process(delta)`                    | Forward ke `current_state.physics_update(delta)`                                                                                                                                                           |
| `on_child_transition(state, new_state_name)` | Handler transisi: abaikan jika `state` bukan `current_state` (mencegah race condition dari state basi); cari state baru di dictionary; panggil `exit()` lama → `enter()` baru                              |

**Catatan desain**: karena lookup pakai `to_lower()` pada nama node, nama node di scene tree (`Idle`, `Move`, `Attack`, `Dash`) **harus match** dengan string yang di-emit di `Transitioned.emit(self, "Attack")` dkk (case-insensitive tapi ejaan harus persis).

### 5.3 `Scripts/Components/velocity_component.gd`

```gdscript
class_name VelocityComponent extends Node
```

Base class gerakan & penentuan arah sprite (dipakai baik oleh Player maupun Dummy, masing-masing lewat subclass).

| Export var | Default | Keterangan              |
| ---------- | ------- | ----------------------- |
| `speed`    | 100.0   | kecepatan dasar         |
| `body`     | —       | CharacterBody2D pemilik |

| Var internal                           | Keterangan                                                                         |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| `current_direction` / `last_direction` | string: `"down" \| "up" \| "left" \| "right"` — dipakai untuk memilih nama animasi |

| Method                                                 | Deskripsi                                                                                                                                                       |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `get_direction_name(input_vector, previous_direction)` | Konversi `Vector2` input jadi nama arah string, dengan prioritas mempertahankan arah sebelumnya jika masih valid, fallback prioritas `down > up > left > right` |
| `get_direction_vector()`                               | Kebalikan dari atas — string arah → `Vector2` (`down/up/left/right`)                                                                                            |
| `knockback(power, origin)`                             | Dorong body menjauhi `origin` sebesar `power`, lalu stop setelah 0.1s                                                                                           |
| `stop_move()`                                          | `velocity = Vector2.ZERO`                                                                                                                                       |

⚠️ **Bug kecil**: di `get_direction_vector()`, baris `print(directions_mapping)` ditulis **setelah** `return`, jadi tidak pernah dieksekusi (sudah ditandai `@warning_ignore("unreachable_code")` oleh penulis — sepertinya sengaja dibiarkan sebagai dead code debug).

### 5.4 `Scripts/Components/player/player_velocity.gd`

```gdscript
extends VelocityComponent
```

| Export var                        | Keterangan        |
| --------------------------------- | ----------------- |
| `input_component: InputComponent` | sumber arah input |

| Method                          | Deskripsi                                                                                                                                                              |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `_physics_process(delta)`       | Update `current_direction` dari input, lalu `body.move_and_slide()`                                                                                                    |
| `move(direction, _speed=speed)` | Set velocity langsung sebesar arah × speed (dipakai state **Move**)                                                                                                    |
| `attack_move(direction)`        | Velocity burst 3× speed searah input (atau 0.5× speed searah hadap terakhir jika tidak ada input), auto-reset ke 0 setelah 0.1s — memberi "lunge" kecil saat menyerang |
| `dash(direction)`               | Velocity burst 5× speed, auto-reset 0.1s — dipakai state **Dash**                                                                                                      |

### 5.5 `Scripts/Components/dummy/dummy_velocity.gd`

```gdscript
extends VelocityComponent
```

Versi minimalis untuk `Dummy`: `_physics_process()` hanya memanggil `body.move_and_slide()` tanpa logic input (karena Dummy statis / tidak dikontrol pemain). Fungsi `_ready()` masih placeholder kosong.

### 5.6 `Scripts/Components/player/input_component.gd`

```gdscript
class_name InputComponent extends Node
```

| Signal              | Keterangan                           |
| ------------------- | ------------------------------------ |
| `direction_changes` | Di-emit tiap kali arah input berubah |

| Var                                   | Keterangan                                                                                                |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `last_direction`, `direction_changed` | tracking perubahan arah                                                                                   |
| `attack_disabled`                     | flag manual lock (saat ini tidak pernah di-set true — fungsi `start_attack_cooldown` terkait dikomentari) |

| Method                  | Deskripsi                                                                   |
| ----------------------- | --------------------------------------------------------------------------- |
| `get_input_direction()` | `Input.get_vector("ui_left","ui_right","ui_up","ui_down")`                  |
| `attack()`              | `true` jika tombol `attack` baru ditekan **dan** `attack_disabled == false` |
| `dash()`                | `true` jika tombol `dash` baru ditekan                                      |

### 5.7 `Scripts/Components/player/player.gd`

```gdscript
extends CharacterBody2D
```

Script utama node root Player. **Bukan** bagian dari FSM — ini "penghubung" antara `InputComponent`, `PlayerActionManager`, dan `StateMachine`.

| Export var                                                                                                           | Keterangan                    |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `velocity_component`, `health_component`, `hitbox_component`, `state_machine`, `animation_player`, `input_component` | wiring ke semua komponen anak |

| Method            | Deskripsi              |
| ----------------- | ---------------------- |
| `_process(delta)` | Logic inti tiap frame: |

Alur `_process()`:

1. Jika tombol attack ditekan **dan** `PlayerActionManager.can_attack`: kunci attack 0.3s (`lock_attack`), lalu paksa FSM pindah ke state **Attack** lewat `Transitioned.emit(current_state, "Attack")` — perhatikan ini emit langsung dari `player.gd`, bukan dari state itu sendiri.
2. Jika tombol attack **tidak** ditekan: akumulasi `no_attack_time`; setelah 1 detik idle dari attack, panggil `PlayerActionManager.reset_attack_state()` (reset combo counter ke 0).
3. Jika tombol dash ditekan **dan** `can_dash`: kunci dash 0.5s, paksa pindah ke state **Dash**.

### 5.8 States Player

**`player_idle.gd`**

- `enter()`: no-op
- `update(delta)`: mainkan animasi `idle_<direction>`
- `physics_update(delta)`: jika ada input arah → transisi ke **Move**

**`player_move.gd`**

- `update(delta)`: mainkan animasi `move_<direction>`
- `physics_update(delta)`: panggil `velocity_component.move(input)`; jika input kosong → transisi ke **Idle**

**`player_attack.gd`**

- `enter()`:
  1. Naikkan `PlayerActionManager.attack_state` (combo counter), wrap ke 1 jika > 4
  2. `anim_state = 1` jika combo ganjil, `2` jika genap → menghasilkan animasi berselang-seling `attack_<dir>1` / `attack_<dir>2` (combo 2-hit per arah)
  3. Mainkan animasi attack sesuai arah & anim_state
  4. `await animation_finished` → otomatis transisi balik ke **Idle**
- `update(delta)`: `velocity_component.attack_move(input)` — memberi lunge saat menyerang
- `exit()`: `velocity_component.stop_move()`

**`player_dash.gd`**

- Konstanta `DASH_TIME = 0.12`
- `enter()`: mulai timer, panggil `velocity_component.dash(input)`
- `physics_update(delta)`: hitung mundur timer; saat habis → `stop_move()`, lalu transisi ke **Move** (jika masih ada input) atau **Idle**

**Diagram alur state**

```
        input arah
Idle ───────────────► Move
 ▲                      │
 │ no input              │ no input
 └──────────────────────┘

Idle/Move ──(tombol attack, can_attack)──► Attack ──(animasi selesai)──► Idle
Idle/Move ──(tombol dash, can_dash)──────► Dash   ──(timer habis)──────► Move / Idle
```

(Transisi ke Attack/Dash dipicu dari `player.gd`, bukan dari state Idle/Move — lihat §5.7.)

### 5.9 `Scripts/Managers/PlayerActionManager.gd` (Autoload)

```gdscript
extends Node
```

| Var                 | Keterangan                         |
| ------------------- | ---------------------------------- |
| `attack_state: int` | combo counter serangan (1–4, wrap) |
| `can_attack: bool`  | gate lock serangan                 |
| `can_dash: bool`    | gate lock dash                     |

| Method                  | Deskripsi                                                            |
| ----------------------- | -------------------------------------------------------------------- |
| `lock_attack(duration)` | `can_attack = false` → tunggu `duration` detik → `can_attack = true` |
| `reset_attack_state()`  | `attack_state = 0` (reset combo)                                     |
| `lock_dash(duration)`   | sama seperti lock_attack tapi untuk dash                             |

### 5.10 `Scripts/Components/heatlh_component.gd`

```gdscript
class_name HealthComponent extends Node
```

| Export var                     | Default | Keterangan                                                      |
| ------------------------------ | ------- | --------------------------------------------------------------- |
| `body`                         | —       | CharacterBody2D pemilik                                         |
| `body_sprite`                  | —       | Sprite2D untuk efek flash                                       |
| `velocity_component`           | —       | untuk trigger knockback dari luar (lihat `damage_component.gd`) |
| `max_health`, `current_health` | 3.0     | HP (Dummy override jadi 100.0 di scene)                         |

| Signal       | Keterangan                                                                                                                  |
| ------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `get_damage` | Di-emit tiap kali `take_damage()` dipanggil (belum ada listener eksplisit di kode saat ini — tersedia untuk UI HP bar dsb.) |

| Method                | Deskripsi                                                                                                   |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `take_damage(amount)` | Kurangi HP, emit `get_damage`, panggil `flash_hit()`, cek kematian                                          |
| `heal(amount)`        | Tambah HP, clamp ke `max_health`                                                                            |
| `die()`               | `body.queue_free()` — **tidak ada animasi kematian / drop item, langsung dihapus**                          |
| `flash_hit()` (async) | Set shader param `hit_flash_on = true` selama 0.2 detik lalu balik `false` — efek kilat putih saat kena hit |

### 5.11 `Scripts/Components/hitbox_component.gd`

```gdscript
class_name HitboxComponent extends Area2D
```

Hanya kontainer data (tidak ada method sendiri) — `Area2D` yang menandai "bagian tubuh yang bisa menerima damage". Diberi group `Hitable` (+ `Player`/`player` khusus punya Player) di scene, agar bisa disaring oleh `damage_component.gd`.

| Export var                                       | Keterangan                        |
| ------------------------------------------------ | --------------------------------- |
| `body`, `health_component`, `velocity_component` | reference balik ke entity pemilik |

### 5.12 `Scripts/Components/damage_component.gd`

```gdscript
extends Area2D
```

Ini adalah **hitbox senjata** (`SwordArea` di scene Player) — kebalikan dari `HitboxComponent` (yang menerima damage, ini yang memberi damage).

| Export var      | Default | Keterangan                    |
| --------------- | ------- | ----------------------------- |
| `body`          | —       | body pemilik senjata (Player) |
| `attack_damage` | 1.00    | damage per hit                |

| Method                   | Deskripsi                                                                                                                                                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `_on_area_entered(area)` | Jika area yang bersentuhan adalah `HitboxComponent`, ada di group `Hitable`, **dan bukan** group `player` (mencegah self-damage) → panggil `take_damage()` pada target, lalu beri knockback 200 dari posisi `body` |

### 5.13 `Scripts/Components/animation_player.gd`

```gdscript
extends AnimationPlayer
```

| Method                                                   | Deskripsi                                                                                                                                                                                                    |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `play_animation(action, direction, reverse_frame=false)` | Bentuk nama animasi `"<action>_<direction>"` (mis. `"move_down"`, `"attack_left1"`), cek `has_animation()`, mainkan (mundur jika `reverse_frame`), kembalikan nama animasi; kalau tidak ada → `push_warning` |

### 5.14 `Scripts/Entity/Dummy/dummy.gd`

```gdscript
class_name Entity extends CharacterBody2D
```

Script root untuk `Dummy` — sangat minimal, hanya kontainer `@export` untuk wiring komponen (`health_component`, `hitbox_component`, `velocity_component`). Tidak ada FSM, tidak ada AI — target statis untuk testing combat.

### 5.15 `Scripts/Tiles/hazard_area.gd`

```gdscript
class_name hazard_area extends Area2D
```

> Catatan: nama class huruf kecil (`hazard_area`) menyalahi konvensi PascalCase Godot untuk `class_name`, tapi tetap valid secara teknis.

| Export var | Default | Keterangan                                                             |
| ---------- | ------- | ---------------------------------------------------------------------- |
| `damage`   | 2.00    | damage per tick kontak (di scene `spikes.tscn` di-override jadi `0.1`) |

| Method                   | Deskripsi                                                                        |
| ------------------------ | -------------------------------------------------------------------------------- |
| `_on_area_entered(area)` | Jika area adalah `HitboxComponent` → `area.health_component.take_damage(damage)` |

Dipakai oleh scene `Obstacles/spikes.tscn` dan beberapa instance duri (`Thorns` TileMapLayer) di `area_test.tscn`.

---

## 6. Referensi Scene

### 6.1 `Scenes/Character/player.tscn`

```
Player (CharacterBody2D, script: player.gd, collision_mask=3)
├── Sprites (Node2D)
│   ├── Body (Sprite2D, spritesheet 6×9 frame, shader: flash_hit)
│   └── AnimationPlayer (17 animasi: idle/move ×4 arah, attack ×4 arah ×2 combo, + RESET)
├── CollisionShape2D (Capsule, r=5 h=14)
├── StateMachine (Node)
│   ├── Idle
│   ├── Move
│   ├── Attack
│   └── Dash
├── InputComponent (Node)
├── VelocityComponent (Node, speed=80)
├── HealthComponent (Node, max_health=3)
├── HitboxComponent (Area2D, groups: Hitable, Player, player)
│   └── CollisionShape2D (Rectangle 8×12)
└── SwordArea (Area2D, damage_component.gd — invisible, collision toggle via animation track)
    └── CollisionShape2D (Rectangle 28×27, disabled by default)
```

**Detail penting**: Track animasi pada tiap `attack_<dir>` **mengubah posisi & `disabled` dari `SwordArea/CollisionShape2D`** secara sinkron dengan frame animasi — collision pedang hanya aktif pada frame tengah serangan (`times: [0, 0.1]`, `disabled: [false, true]`), lalu posisinya digeser sesuai arah tebasan (`Vector2(0,16)` untuk down, `Vector2(-16,0)` untuk left, dst).

### 6.2 `Scenes/Character/dummy.tscn`

```
CharacterBody2D (script: dummy.gd)
├── Sprite2D (shader: flash_hit)
├── CollisionShape2D (Capsule r=5 h=14)
├── HealthComponent (max_health=100)
├── HitboxComponent (Area2D, group: Hitable)
│   └── CollisionShape2D (Rectangle 10×18)
└── VelocityComponent (dummy_velocity.gd)
```

Tidak ada `InputComponent`/`StateMachine` — Dummy murni pasif, hanya bisa menerima damage & knockback.

### 6.3 `Scenes/Obstacles/spikes.tscn`

```
Spikes (Area2D, hazard_area.gd, damage=0.1)
├── Sprite2D
└── CollisionShape2D
```

### 6.4 `Scenes/UI/button.tscn`

```
Button (TextureButton)
  texture_normal / texture_focused dari Assets/UIs/Button/
```

Belum ada script — murni visual template tombol.

### 6.5 `Scenes/area_test.tscn` (⭐ Main Scene)

```
AreaTest (Node2D)
├── Tilemap (Node2D)
│   ├── Ground, Cliff1, Shadow, Thorns, Path, Tree  (semua TileMapLayer, tileset: tile_set.tres)
│   └── (beberapa instance Area2D duri di layer Thorns terhubung ke hazard_area.gd)
├── Player (instance player.tscn)
│   └── Camera2D (zoom 1.4×, smoothing on)
└── Dummy (instance dummy.tscn, posisi test di (127,-87))
```

Level uji sederhana: tilemap grass/cliff/path/tree berlapis, area duri, satu Player dengan kamera mengikuti, satu Dummy untuk latihan combat.

### 6.6 `Scenes/propechy.tscn`

Scene showcase terpisah untuk shader `sssss.gdshader` (lihat §9.2) — menampilkan sprite "prophecy" dengan efek echo/scrolling di atas background biru, dengan Camera2D zoom 4×. Sepertinya scene eksperimen/test shader, belum terhubung ke gameplay utama.

---

## 7. Sistem Combat & Damage — Alur End-to-End

1. Pemain tekan **attack** → `player.gd._process()` cek `PlayerActionManager.can_attack` → kunci 0.3s → FSM pindah ke **Attack**.
2. **Attack.enter()** naikkan combo counter, pilih animasi `attack_<arah><1|2>`, mainkan.
3. Track animasi mengaktifkan `SwordArea` (`damage_component.gd`) tepat di frame tengah, memposisikannya searah tebasan.
4. Jika `SwordArea` overlap dengan `HitboxComponent` musuh (group `Hitable`, bukan `player`) → `_on_area_entered()` panggil `target.health_component.take_damage()` + `knockback()`.
5. `HealthComponent.take_damage()` kurangi HP, trigger **flash putih** via shader `flash_hit.gdshader`, dan jika HP ≤ 0 → `queue_free()` (entity langsung hilang).
6. Setelah animasi attack selesai → otomatis kembali ke **Idle**.
7. Alternatif damage: kontak langsung dengan `hazard_area.gd` (duri) — tidak butuh serangan aktif, cukup `HitboxComponent` overlap area bahaya.

---

## 8. Shader

### 8.1 `Shaders/flash_hit.gdshader`

Shader `canvas_item` sederhana — 2 uniform (`hit_flash_color`, `hit_flash_on`). Saat `hit_flash_on == true`, warna sprite diganti total jadi `hit_flash_color` (default putih) sambil mempertahankan alpha asli. Dipasang sebagai material di sprite Player & Dummy, dikontrol dari `HealthComponent.flash_hit()`.

### 8.2 `sssss.gdshader`

Shader jauh lebih kompleks — efek "echo/afterimage + scrolling texture + bobbing", dipakai di scene showcase `propechy.tscn`. Fitur:

- **Scrolling texture**: geser tekstur sekunder (`Scroll_Texture`) secara berkelanjutan sebagai background berjalan.
- **Bobbing**: sprite naik-turun sinusoidal (`Height`, `Cycles`, `Offset`).
- **Echoes**: menggambar N salinan sprite bergeser progresif dengan alpha meluruh (`Distance`, `Count`, `Fade`), opsional dua arah (`Pulse_both_Directions`), dua mode blending (Mix / Additive), dengan tint warna progresif.
  Shader ini tidak dipakai di gameplay utama saat ini — statusnya eksperimen visual/VFX untuk fitur masa depan (kemungkinan efek "phantom"/hantu atau item mistis, mengingat nama file `my_propechy.png`).

---

## 9. Addon Pihak Ketiga — `discord-rpc-gd`

Terletak di `addons/discord-rpc-gd/`. Ini adalah addon eksternal (GDExtension, binary `.so`/`.dll`/`.dylib` untuk Linux/Windows/macOS) untuk integrasi **Discord Rich Presence** via Discord Game SDK. Berisi:

- `plugin.gd` — entry point plugin editor
- `nodes/discord_autoload.gd` — node autoload opsional untuk RPC
- `nodes/debug.gd` + `Debug.tscn` — panel debug in-editor
- `example.gd` — contoh pemakaian API

Status saat ini: **plugin belum diaktifkan** — `project.godot` bagian `[editor_plugins]` masih `enabled=PackedStringArray()` (kosong). Jadi addon ini sudah tersedia di project tapi belum di-enable/dipakai di kode game.

---

## 10. Catatan Teknis & Potensi Perbaikan

Beberapa temuan selama analisis code (bukan bug fatal, sekadar catatan untuk cleanup ke depan):

1. **Typo penamaan file/class** — `heatlh_component.gd` (harusnya "health"), `state_mechine.gd` (harusnya "machine"), class `hazard_area` tidak PascalCase. Tidak memengaruhi fungsi, tapi bisa membingungkan saat autocomplete/search.
2. **`InputComponent.attack_disabled`** disiapkan sebagai flag lock manual, tapi fungsi `start_attack_cooldown()` yang men-set-nya sudah dikomentari — lock cooldown attack saat ini sepenuhnya ditangani oleh `PlayerActionManager`, jadi field ini efektif tidak terpakai.
3. **`HealthComponent.die()`** langsung `queue_free()` tanpa animasi kematian, sound, drop, atau signal `died` — kemungkinan placeholder untuk dikembangkan.
4. **Transisi ke Attack/Dash** dipicu langsung dari `player.gd` (bukan dari dalam state `Idle`/`Move`), sedikit tidak konsisten dengan pola FSM murni di mana idealnya semua logic transisi state ada di dalam state itu sendiri — tapi ini pilihan desain yang valid mengingat attack/dash bisa dipicu dari state manapun (interrupt).
5. Ditemukan file sisa proses save Godot yang belum ke-cleanup: `Scenes/Character/filint.tscn*.tmp` (5 file `.tmp`) — aman dihapus, biasanya residu crash/autosave editor.
6. Beberapa aset di `Assets/Unknown/` tampak duplikat/typo (`my_propechy.png` vs `my_prophecy.png`) — kemungkinan sisa eksperimen, bisa dirapikan.
7. Scene `propechy.tscn` dan shader `sssss.gdshader` sepertinya masih tahap eksperimen VFX, belum terhubung ke `area_test.tscn` (main scene).

---

## 11. Ringkasan Dependency Antar Komponen

```
PlayerActionManager (Autoload)
        ▲
        │ lock/read state
        │
   player.gd ──emit Transitioned──► StateMachine ──► Idle/Move/Attack/Dash (State)
        │                                                   │
        ├──uses──► InputComponent                            ├──uses──► VelocityComponent (player_velocity.gd)
        │                                                   └──uses──► AnimationPlayer (animation_player.gd)
        │
        └──has──► HealthComponent ──uses shader──► flash_hit.gdshader
                         ▲
                         │ take_damage()
                         │
        SwordArea (damage_component.gd) ──overlap──► HitboxComponent (target)
                                                              │
                                                     hazard_area.gd (duri) juga bisa trigger take_damage()
```

---

_Dokumen ini dibuat otomatis berdasarkan pembacaan langsung seluruh source code di repo (per 10 Juli 2026). Jika struktur project berubah, regenerasi dokumen ini disarankan._
