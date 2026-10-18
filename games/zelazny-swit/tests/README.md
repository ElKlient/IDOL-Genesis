# Runtime checks

Run from the Godot project directory with Godot 4.4 or newer:

```sh
godot --headless --path . --script res://tests/integration.gd -- --test-isolated
godot --headless --path . --script res://tests/ui_flow.gd -- --test-isolated
godot --headless --path . --script res://tests/render_stability.gd -- --test-isolated
godot --headless --path . --script res://tests/forge_deferred.gd -- --test-isolated
godot --headless --audio-driver Dummy --path . --script res://tests/audio_regression.gd -- --test-isolated
```

`integration.gd` checks starting gold, prices, equipment, upgrade costs, healing, quest rewards, actual touch joystick movement, collision routes to both NPCs and through the gate, three real enemy kills through attack windup/cooldown, and their timed respawn. It also checks that every modal fits a 1280 × 720 viewport. The respawn check waits for the real 18-second cooldown.

`ui_flow.gd` sends real GUI pointer events: select and buy a sword, open the inventory, equip it, drag it onto the anvil, and press the upgrade button. It verifies that dropping only selects the item and that the explicit upgrade action charges once. It also covers reset confirmation and a fresh scene. Pointer helpers scroll ancestor `ScrollContainer` nodes to expose the real target before clicking; tree visibility alone does not imply that a control is inside its scroll viewport.

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

`diagnostics_network.gd` is a separate explicitly authorized live smoke test. It requires `--diagnostics-network-test` without `--test-isolated`, a disposable `XDG_DATA_HOME` matching `--test-data-root`, and private local `user://diagnostics_config.json` provisioned outside the repository. It queues a real Godot report, waits at most 20 seconds for acknowledgement/removal and checks confirmed sent status. It prints only the opaque report identifier and test results; never put credentials in command-line arguments or repository files.

To capture real rendered previews, use an active graphical display or Xvfb. This check cannot use `--headless`:

```sh
godot --path . --resolution 1280x720 --script res://tests/capture_preview.gd -- --test-isolated --capture-dir=/absolute/path/to/previews
```

It saves the village, merchant, forge, inventory, combat, and a 1600 × 720 phone aspect preview. These captures use the actual project renderer and clear transient notifications before each screenshot.
