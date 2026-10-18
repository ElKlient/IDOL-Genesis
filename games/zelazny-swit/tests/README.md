# Runtime checks

Run from the Godot project directory with Godot 4.4 or newer:

```sh
godot --headless --path . --script res://tests/integration.gd -- --test-isolated
godot --headless --path . --script res://tests/ui_flow.gd -- --test-isolated
godot --headless --path . --script res://tests/combat_combo.gd -- --test-isolated
godot --headless --path . --script res://tests/render_stability.gd -- --test-isolated
godot --headless --path . --script res://tests/forge_deferred.gd -- --test-isolated
godot --headless --audio-driver Dummy --path . --script res://tests/audio_regression.gd -- --test-isolated
```

`integration.gd` checks starting gold, prices, equipment, upgrade costs, healing, quest rewards, actual touch joystick movement, collision routes to both NPCs and through the gate, three real enemy kills through attack windup/cooldown, and their timed respawn. It also checks that every modal fits a 1280 × 720 viewport. The respawn check waits for the real 18-second cooldown.

`ui_flow.gd` sends real GUI pointer events: select and buy a sword, open the inventory, equip it, drag it onto the anvil, and press the upgrade button. It verifies that dropping only selects the item and that the explicit upgrade action charges once. It also covers reset confirmation and a fresh scene. Pointer helpers scroll ancestor `ScrollContainer` nodes to expose the real target before clicking; tree visibility alone does not imply that a control is inside its scroll viewport.

`combat_combo.gd` exercises four real main-controller attacks, contact timing, cooldown/modal/range/death guards, the 1.2-second combo reset, finisher-only impulse decay, enemy windup interruption and collision against a temporary wall. It verifies one defeat reward, exact camera focus during movement/stops/teleports, four distinct blade contacts in front of the warrior above ground, bounded idle breathing, and safe transition from a skill spin. The real enemy fixture avoids respawn timers; the full integration test covers spawned-enemy rewards and respawn. On an OpenGL display, omit `--headless` and add `--capture-dir=/absolute/path/to/previews` for the actual idle pose and four contact-pose screenshots. Version 0.1.6 passed 55 headless checks and 60 checks with these captures.

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
