# Runtime checks

Version 0.2.5 ordinary-attack timing on Godot 4.6 / Linux, with isolated
saves and disabled diagnostic networking:

| Check | Headless |
| --- | ---: |
| `attack_speed.gd`: real controller, contact pose, audio, cancellation, held input and portrait at 100/125/150/200 | 191/191 |
| `combat_combo.gd`: real contacts, recovery, reset and fourth-hit knockback | 63/63 |
| `attack_audio_timing.gd`: delayed whooshes and cancellation | 8/8 |
| `attack_facing.gd`: committed facing through complete cuts at four speeds | 49/49 |
| `animation_continuity.gd`: complete cuts, four weapon sizes, support grip | 69/69 |
| `stance_motion.gd`: breathing, planted stance, raised guard and all recoveries | 56/56 |
| `warrior_model.gd`: imported skin, armor deformation and portrait framing | 40/40 |
| `integration.gd`: shop, forge, real kills and respawn | 51/51 |
| `fire_skill.gd`: separate skill timing, interruption and buff expiry | 38/38 |
| `character_preview.gd`: live inventory controls and bounded rendering | 32/32 |

The attack-speed test timestamps actual events using physics frames. It checks
one whoosh before one hit per cut and samples `attack_elapsed` inside the real
enemy damage signal, allowing at most two physics frames of quantization.
Changing a bonus during a windup must affect the next accepted cut only.
The fixture checks ordinary recovery protection even with a forced zero
cooldown, all four cancellation modes, and the actual inventory CIOS action.
Existing geometry/continuity budgets were preserved; longer clips are sampled
through their full duration instead of stopping at an old fixed frame count.

```sh
godot --headless --audio-driver Dummy --path . --script res://tests/attack_speed.gd -- --test-isolated
godot --path . --script res://tests/capture_attack_rhythm.gd --fixed-fps 30 --write-movie /absolute/rhythm.avi -- --test-isolated --capture-dir=/absolute/rhythm-images
```

The second command needs a graphical display. Unlike the posed showcase below,
it leaves the real player/controller physics running, including hit timers and
audio. Enemy AI is stopped and its HP increased solely for recording. It checks
four actual hits at base 100 and four with a temporary test-only +50% speed
bonus. Neither that fixture bonus nor its extra enemy HP is normal game balance.
The recording is an engine render at fixed 30 FPS, not measured phone performance.

Version 0.2.4 raised-guard regression on Godot 4.6: `stance_motion.gd`
56/56, `animation_continuity.gd` 69/69, `warrior_model.gd` 40/40,
`combat_combo.gd` 55/55, `character_preview.gd` 32/32, `fire_skill.gd` 38/38,
`integration.gd` 51/51, including real shop/forge/kills and respawn.
The guard test checks upward direction both in world space and when projected
onto a 45-degree elevated front view, plus planted feet and all six recoveries.
The late ordinary-cut step is at most 2.23 cm per 1/120 s in the sampled motion;
final joins remain below 0.4 mm. Existing continuity limits were preserved.

For quick actual OpenGL guard stills with the largest sword and armor:

```sh
godot --path . --script res://tests/capture_stance.gd -- --test-isolated --guard-review --capture-dir=/absolute/guard-images
```

This captures front, side, elevated gameplay-camera and inventory views.
It is a posed rendering check, not a phone-performance measurement.
For a short actual second-cut/finisher timing movie, replace `--guard-review`
with `--guard-motion` and add `--fixed-fps 30 --write-movie /absolute/guard.avi`
before `--`. The short mode ticks the visual at 30 Hz for three seconds.

Version 0.2.3 animation checks on Godot 4.6, isolated from saves and networking:

| Check | Headless |
| --- | ---: |
| `stance_motion.gd`: twelve-second idle, planted feet, low guard, all six action recoveries and profile validation | 56/56 |
| `animation_continuity.gd`: four cuts with all four weapon sizes, full roll and support grip | 69/69 |
| `warrior_model.gd`: actual skin, soles, two-hand slam and portrait framing | 40/40 |
| `combat_combo.gd`: actual contact times, four hits and finisher | 55/55 |
| `character_preview.gd`: animated inventory, drag, framing and hidden rendering | 32/32 |
| `fire_skill.gd`: real impact/buff timing, interruption and expiry | 38/38 |
| `integration.gd`: real shop/forge/combat and eighteen-second respawn | 51/51 |

Idle head movement is approximately 1.4–1.55 cm over the sampled cycle, with
stationary foot anchors. The longest carried sword remains over 42 cm above
the floor. New recovery sampling caught an initial fire-slam wrist flip of
14.8–18.3 cm per 1/120 s; coherent hilt/orientation recovery fixed it.
The last frame joins the live guard within 0.4 mm in these samples. These
measurements complement visual review; they do not prove animation taste.

Reproduce the actual 15-second animation showcase on a graphical display:

```sh
godot --path . --script res://tests/stance_motion.gd -- --test-isolated
godot --path . --script res://tests/capture_stance.gd --fixed-fps 60 --write-movie /absolute/stance.avi -- --test-isolated --capture-dir=/absolute/stance-images
```

The recording uses actual game assets and a close presentation camera, with
AI and controller simulation paused. It calls the visual animation interface
to show idle front/side/back, running in place, four cuts, slam and inventory.
It is an animation recording, not a gameplay damage demonstration or phone FPS
measurement. The normal game still uses the tested controller timing.

Version 0.2.2 world graphics: `world_materials.gd` passed 28/28 on actual
Godot 4.6 Compatibility/OpenGL. It preserves the exact walking/roof collision
signatures, checks all shared terrain resources and actual mip chains, verifies
the character-only nonshadowed fill and both quality paths, and measures
91,856 full-map triangles / 61 surfaces (a deliberate 100k / 66 ceiling).
The original eight material families use 10,485,744 image bytes; the two new
shared maps add less than 3 MiB including mipmaps. Model/layer regression
passed 40/40 under OpenGL, and full gameplay integration passed 51/51 headless.
Renderer/forge quality regression passed 54/54 headless and 65/65 OpenGL,
including ten quality toggles, three upgrades and unchanged startup MSAA.
These checks do not establish Android FPS.

Use a real graphical display to reproduce the current gameplay images:

```sh
godot --path . --script res://tests/capture_valley.gd -- --test-isolated --capture-dir=/absolute/output/path
```

The fixture buys third-tier equipment and pauses enemy AI for screenshots;
normal game balance and starting equipment are unchanged. It captures the
village, wilderness, pond and flaming sword without editing a player save.

Run from the Godot project directory with Godot 4.4 or newer:

```sh
godot --headless --path . --script res://tests/integration.gd -- --test-isolated
godot --headless --path . --script res://tests/ui_flow.gd -- --test-isolated
godot --headless --path . --script res://tests/combat_combo.gd -- --test-isolated
godot --headless --path . --script res://tests/animation_continuity.gd -- --test-isolated
godot --headless --path . --script res://tests/attack_facing.gd -- --test-isolated
godot --headless --audio-driver Dummy --path . --script res://tests/attack_audio_timing.gd -- --test-isolated
godot --headless --path . --script res://tests/character_preview.gd -- --test-isolated
godot --headless --path . --script res://tests/fire_skill.gd -- --test-isolated
godot --headless --path . --script res://tests/warrior_model.gd -- --test-isolated
godot --headless --path . --script res://tests/graphics_hd.gd -- --test-isolated
godot --headless --path . --script res://tests/impact_hd.gd -- --test-isolated
godot --headless --path . --script res://tests/world_materials.gd -- --test-isolated
godot --headless --path . --script res://tests/render_stability.gd -- --test-isolated
godot --headless --path . --script res://tests/forge_deferred.gd -- --test-isolated
godot --headless --audio-driver Dummy --path . --script res://tests/audio_regression.gd -- --test-isolated
```

`integration.gd` checks starting gold, prices, equipment, upgrade costs, healing, quest rewards, actual touch joystick movement, collision routes to both NPCs and through the gate, three real enemy kills through attack windup/cooldown, and their timed respawn. It also checks that every modal fits a 1280 × 720 viewport. The respawn check waits for the real 18-second cooldown.

`ui_flow.gd` sends real GUI pointer events: select and buy a sword, open the inventory, equip it, drag it onto the anvil, and press the upgrade button. It verifies that dropping only selects the item and that the explicit upgrade action charges once. It also covers reset confirmation and a fresh scene. Pointer helpers scroll ancestor `ScrollContainer` nodes to expose the real target before clicking; tree visibility alone does not imply that a control is inside its scroll viewport.

`combat_combo.gd` exercises four real main-controller attacks, contact timing, cooldown/modal/range/death guards, the 1.2-second combo reset, finisher-only impulse decay, enemy windup interruption and collision against a temporary wall. It verifies one defeat reward, exact camera focus during movement/stops/teleports, four distinct blade contacts in front of the warrior above ground, bounded idle breathing, and safe transition from a skill spin. The real enemy fixture avoids respawn timers; the full integration test covers spawned-enemy rewards and respawn. On an OpenGL display, omit `--headless` and add `--capture-dir=/absolute/path/to/previews` for the actual idle pose and four contact-pose screenshots. Version 0.1.6 passed 55 headless checks and 60 checks with these captures.

`animation_continuity.gd` samples the actual equipped sword transforms at 120 Hz
through all four complete cuts and all four equipment sizes, including the first
and recovery frames. It checks finite positions, a scale-normalized tip-step
limit, blade-axis and full-basis rotation continuity, floor clearance, and the
fourth strike’s actual support wrist against its scaled hilt. The 1.5 cm grip
threshold catches unreachable targets even when the independent fire-slam grip
checks pass. This is a regression guard against discontinuities, not a substitute
for reviewing the actual animation recording. The initial 0.2.1 pass completed
69 checks; the largest full-basis step was 16.73 degrees per 1/120 s and the
smallest sampled tip-floor clearance was 17.4 cm across the sixteen attacks.

`attack_facing.gd` checks that joystick steering cannot turn the visible hero
away from the attack’s committed direction during an ordinary cut. Movement
continues at the established attack speed and steering resumes on recovery.
`attack_audio_timing.gd` checks ordinary and heavy delayed swing sound calls and their
cancellation when an attack is interrupted. These checks use isolated gameplay
and the Dummy audio driver, with no diagnostic network traffic.

Verified 0.2.1 animation regression results on Godot 4.6 / Linux:

| Check | Isolated headless |
| --- | ---: |
| Sword continuity and two-hand reach | 69/69 |
| Real combo and finisher gameplay | 55/55 |
| Imported model / skinning | 39/39 |
| Inventory preview | 32/32 |
| Fire skill and camera controls | 38/38 |
| Facing while moving and cutting | 13/13 |
| Delayed swing audio cancellation | 8/8 |
| Full main-controller integration / real respawn | 50/50 |

The final OpenGL `warrior_model.gd` run also passed 50/50 checks, including
eleven actual current-motion captures. Its full-body skinning and portrait
framing assertions remain unchanged.

The recording uses the real main-controller attack path. Its wolf fixture has
extra health and paused enemy AI solely to show two complete combos clearly;
these fixture settings are not gameplay balance changes. Rendering under Linux/Mesa does not measure Android performance.

`character_preview.gd` opens the actual inventory and exercises mouse/touch rotation, exclusive finger ownership, emulated-mouse suppression, cancelled touches, and the animation/rotation buttons. Equipping the third-tier sword/armor and rebuilding or reopening panels must preserve one preview, one 512 × 512 viewport and the chosen yaw. It checks 1280 × 720 and 1600 × 720 layout, full rotation, all four complete swings at eleven animation times and eight viewing angles, the bounded 30 Hz render-request clock, and zero hidden animation/render requests. Rigid curved blades are projected from actual vertices rather than the empty corners of their bounding box; `warrior_model.gd` separately checks the deformed skin. OpenGL runs can add `--capture-dir=/absolute/path/to/previews` for both inventory sizes.

`fire_skill.gd` invokes the real fire button and physical F key. Real enemy fixtures check the contact delay, one area hit, range, attack/movement locks, twenty-second cooldown, thirty-percent ordinary-cut damage bonus, and natural twelve-second expiration. It also checks immediate modal and death cancellation, invalidation of a pending older cut, live/hidden inventory flames, effect disposal, unchanged permanent attack stats and equipment, actual mouse camera orbit, simultaneous left joystick/right camera touch ownership, pitch/yaw bounds, and emulated-mouse suppression on the attack pad and world target picker. Isolated camera preference writes remain disabled. On OpenGL, `--capture-dir=/absolute/path/to/previews` captures the windup, impact, burning sword and inventory. Only the rendered windup is slowed to avoid skipping that pose during initial shader compilation; subsequent gameplay and the natural buff expiry use normal simulation speed. These Linux checks are not a physical-phone frame-rate measurement.

`warrior_model.gd` checks the actual imported warrior and weapons in the playable
scene and inventory. It requires a weighted continuous body, an articulated
skeleton and natural adult proportions; a primitive fallback cannot pass. It
counts only visible geometry across all four armor/weapon stages, with a ceiling
of 35,000 triangles and twelve material surfaces per warrior. Main and portrait
share immutable mesh/skin data while their mutable equipment materials remain
independent. CPU skinning of the imported vertices verifies that running, all
four cuts and the two-handed slam actually deform the body and armor without invalid or
exploded coordinates. Deformed skin and real blade vertices must stay inside the
portrait through all four cuts and eight viewing angles. The planted blade tip,
support hand and actual boot sole are measured for all four weapon sizes,
and the flame must remain attached to that sword. Existing save
bytes remain unchanged and telemetry stays disabled. On a real OpenGL display,
add `--capture-dir=/absolute/path/to/warrior-previews` to save village, front/side
inventory, run, four contact poses, raised/planted slam and burning-sword PNGs.
These are actual project renders, not concept illustrations or Android FPS claims.
The final 0.1.8 asset passed 39 isolated headless checks and 50 OpenGL checks
including eleven captures. Actual armor plus sword totals are 9,923 / 13,775 /
14,407 / 15,541 visible triangles across tiers 0–3, with at most fourteen opaque
material surfaces. Seven shared textures have a maximum dimension of 1024 pixels.
The planted blade tip is 7 cm above ground; actual boot soles remain at 1.3–2.0 cm
for all four sword sizes. These are asset and geometry measurements, not a
measurement of the phone's frame rate or actual driver texture allocation.

`graphics_hd.gd` checks the real 0.2 equipment package in both the game and the
inventory. The four imported armor and sword stages must use distinct geometry,
normalized finite skin weights and the shared PBR atlas over actual UV regions.
The material must enable normal maps and occlusion, with the same ORM image bound
to roughness green, metallic blue and occlusion red. Source PNG pixels must
contain real color/normal/roughness/metal variation; the separate blade emission
mask must contain sparse details rather than a solid glowing blade.

The three 1024-square PBR maps stay shared between armor, sword, player and
portrait. Two 256-square emission maps keep armor gems separate from upgrade
glow. Together with the original body maps, the actor must stay within twelve
shared textures and a maximum image dimension of 1024. The test prints visible
triangle/surface budgets and an RGBA8 plus mipmap texture-memory upper bound;
these are asset measurements, not the phone driver's actual allocation or FPS.

CPU skinning checks the actual body, armor and blade vertices through idle,
running, presentation, all four cuts and the two-handed slam, at eight viewing
angles for all three families. Default framing must show the entire geometry;
the resting equipment must also avoid all nine overlay buttons, including the
boots above the footer. The fourth cut's support hand must meet the real hilt.
Actual mouse events exercise the zoom, reset and POZA buttons without moving or
attacking with the playable hero. Equipping the real inventory items keeps the
portrait, statistics and rendered family consistent. All seven inventory items
and long family names must fit both phone aspect ratios, with one overlay tree,
no horizontal overflow and zero hidden rendering. Rapid long purchase/upgrade
messages must retain a centered 600-pixel toast at no more than 76 pixels high;
switching back to short text cannot grow or displace it. OpenGL runs can add
`--capture-dir=/absolute/path/to/previews` for real front, side and detail
inventory captures, village views of all three sets, and sword-ground contact.
User-selected close-up zoom deliberately crops the body; full-body framing is
checked at the default zoom rather than weakening the geometry bounds.

`impact_hd.gd` independently checks the reusable contact renderer. Eight effects
may run simultaneously; one hundred retriggers must retain the same three
bounded MultiMesh batches and the exact active count. All actual instance
transforms must stay finite, contact marks must remain in world space during
owner movement, and expiry/freeing must return every slot and stop processing.
Invalid inputs cannot consume a slot. A real enemy hit must charge damage once,
animate a directional local flinch, then return exactly to neutral. Contact
pause must hold only the visible attack clock, leave `Engine.time_scale`
unchanged, resume, and clear on cancellation. A verified run passed 17 headless
checks.

`world_materials.gd` checks visible surface/triangle budgets, shared material
images at 512 albedo / 256 normal, actual UV/tangent data and the static
128-resolution sky. Walking colliders, camera-only roofs, NPC access and enemy
spawns must retain their established positions. Material sharing must survive
another world instance and quality toggles. World textures are counted separately
from the character atlas; no player-save or diagnostic-network writes occur.
The final world check passed 18 headless checks and 19 OpenGL checks. Its tangent
frame test compares actual UV derivatives for 20,324 triangles against Godot's
`PlaneMesh` convention, rather than merely checking that tangents exist.

Verified 0.2.0 results for the final V7 package:

| Check | Headless | OpenGL |
| --- | ---: | ---: |
| `graphics_hd.gd` | 69/69 | 85/85, including 16 actual captures |
| `warrior_model.gd` | 39/39 | Covered by the HD package run |
| `impact_hd.gd` | 17/17 | Contact effects also inspected in the actual recording |
| `world_materials.gd` | 18/18 | 19/19 |
| Imported item icons | — | 21/21 real controls; 23/23 fresh-import alpha/framing checks |

The final OpenGL HD run used a clean source-only copy, without the original
`.godot` directory, generated body PNGs, UID files or private configuration.
Godot imported the embedded body images, all five canonical equipment maps and
seven final model-rendered icon PNGs from source. Only the expected headless
Dummy thumbnail `texture_2d_get` messages appeared during import; the actual
OpenGL runtime had no script/resource errors. These Linux/Mesa results do not
establish physical-Android frame rate or certify a particular mobile driver.

Actual visible rest equipment budgets, including the body and equipped sword:

| Stage | Triangles | Material surfaces |
| --- | ---: | ---: |
| Starter | 12,491 | 7 |
| Karmazynowa Straż | 25,575 | 8 |
| Jadeitowa Brama | 25,281 | 8 |
| Popielny Żar | 25,501 | 8 |

The actor and portrait share twelve textures. Their combined texture set is
33 MiB at RGBA8 base level, or a 44 MiB upper bound including a complete mip
chain, shared rather than doubled for the portrait. This excludes framebuffers,
shadows, effect resources and world textures and is not an actual driver memory
measurement. Fitting the actual deformed geometry also confirms clear default
portrait boots, full rotation and both-handed grip for the fourth contact.

`render_stability.gd` keeps the real scene active for at least 12 seconds, crossing the former eight-second automatic graphics transition. It upgrades the actual starter sword to +1, +2 and +3 through the forge button, checks each charge and equipped armor, and repeatedly toggles economical graphics. Every toggle must retain the viewport's startup MSAA setting while still switching sun shadows and forge lighting. The same test can run on a real OpenGL display (omit `--headless`, optionally use Xvfb); it then also checks that rendered frames continue after every toggle. This is a targeted renderer regression, not a claim of testing every Android GPU.

`forge_deferred.gd` exercises the actual forge button and verifies that model mutation waits until GUI signal dispatch finishes, repeated signals charge once, pending state changes join a single deferred panel rebuild, closing/reopening cancels an old action, and switching the selected UID prevents a stale charge. Repeated panel rebuilds must leave one live content tree and clear pending guards.

`audio_regression.gd` plays the actual eight-second ambient WAV on the audio driver's Dummy backend, waits for its natural `finished` signal, and checks deferred replay of the same resource. It also tests sound effect disposal, muting before a queued replay, unmuting, and leaving the scene. Native WAV looping must stay disabled. This test lasts about ten seconds; checking only stream metadata would not exercise the original boundary.

The 0.1.2 fixes and these Linux tests do not establish the cause of the reported Android process exit or certify a physical Android device.

These scene tests refuse to run without `--test-isolated`. This flag disables saving and diagnostic network traffic, using separate local diagnostic files; the integration and renderer checks verify that an existing player's save is unchanged. Never put a private bearer token into a test fixture or commit.

For persistence checks, use a disposable data directory:

```sh
qa_data="$(mktemp -d)"
XDG_DATA_HOME="$qa_data" godot --headless --path . --script res://tests/persistence.gd -- --test-isolated --test-data-root="$qa_data"
```

The persistence test refuses to write unless Godot's actual data directory is inside the explicitly supplied disposable directory. It checks full save/reload, equipment reconstruction, backup recovery, invalid numeric and boolean fields, invalid inventory identifiers/upgrades/duplicate UIDs, and preservation of corrupted data. JSON parser errors from intentionally broken samples are expected; the final `PERSISTENCE RESULT` reports the result.

Diagnostics privacy and recovery also use a disposable data directory:

```sh
qa_data="$(mktemp -d)"
XDG_DATA_HOME="$qa_data" godot --headless --path . --script res://tests/diagnostics.gd -- --test-isolated --test-data-root="$qa_data"
```

This checks bounded/redacted breadcrumbs, error-tail filtering, bounded offline queue files, opt-out persistence and deletion, and the distinction between unclosed foreground, paused and clean sessions. It also verifies that HTML success pages, wrong report IDs and server rejections retain the report, while matching accepted JSON acknowledges only that report. Isolated diagnostics always disables networking.

`diagnostics_network.gd` is a separate explicitly authorized live smoke test. It requires `--diagnostics-network-test` without `--test-isolated`, a disposable `XDG_DATA_HOME` matching `--test-data-root`, and private local `user://diagnostics_config.json` provisioned outside the repository. It queues a real Godot report, waits at most 20 seconds for acknowledgement/removal and checks confirmed sent status. It prints only opaque report identifiers, numeric transport phases/results and test results; never put credentials in command-line arguments or repository files. Managed QA can pass `--test-https-proxy=host:port` to use its local CONNECT proxy without changing production configuration. The production request timeout is 15 seconds from version 0.1.3.

Camera geometry, touch controls and persistence use their own disposable directory:

```sh
qa_data="$(mktemp -d)"
XDG_DATA_HOME="$qa_data" godot --headless --path . --script res://tests/camera_settings.gd -- --test-isolated --test-data-root="$qa_data"
```

`camera_settings.gd` measures projected warrior height against the previous fixed camera, checks zoom/pitch/orbit limits, and places a temporary collision wall between the focus and desired camera endpoint. The spring arm must shorten, keep the eye outside the wall, and recover its original length after removal. Real joystick input must continue moving up/right on screen at four orbit angles. Pointer input exercises all three live sliders and the reset button; the compact preview panel must leave the warrior visible at 1280 × 720 and 1600 × 720.

The closer-camera regression also loads existing settings `1.85 / 38° / 0°` unchanged, compares the previous 20.2 camera distance with the new 17.0 distance at those same settings, and verifies the expanded zoom maximum of 2.50. Optional OpenGL captures show the hunter sword and third armor tier at the existing saved zoom and at the new maximum.

The camera test explicitly enables preference persistence only inside the guarded disposable directory, verifies both the standalone preference file and main controller's debounced save/reload, and requires an older-format character-save fixture to remain byte-for-byte unchanged. Run this same test on an active OpenGL display without `--headless` and add `--capture-dir=/absolute/path/to/previews` to save default-camera and live-panel screenshots at both phone aspect ratios. Isolated mode prevents telemetry sends.

To capture real rendered previews, use an active graphical display or Xvfb. This check cannot use `--headless`:

```sh
godot --path . --resolution 1280x720 --script res://tests/capture_preview.gd -- --test-isolated --capture-dir=/absolute/path/to/previews
```

It saves the village, merchant, forge, inventory, combat, and a 1600 × 720 phone aspect preview. These captures use the actual project renderer and clear transient notifications before each screenshot.
