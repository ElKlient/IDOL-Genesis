# Runtime checks

Run from the Godot project directory with Godot 4.4 or newer:

```sh
godot --headless --path . --script res://tests/integration.gd -- --test-isolated
godot --headless --path . --script res://tests/ui_flow.gd -- --test-isolated
```

`integration.gd` checks starting gold, prices, equipment, upgrade costs, healing, quest rewards, actual touch joystick movement, collision routes to both NPCs and through the gate, three real enemy kills through attack windup/cooldown, and their timed respawn. It also checks that every modal fits a 1280 × 720 viewport. The respawn check waits for the real 18-second cooldown.

`ui_flow.gd` sends real GUI pointer events: select and buy a sword, open the inventory, equip it, drag it onto the anvil, and press the upgrade button. It verifies that dropping only selects the item and that the explicit upgrade action charges once.

These two scripts refuse to run without `--test-isolated`. This flag disables saving, and the integration check verifies that an existing player's save is unchanged.

For persistence checks, use a disposable data directory:

```sh
qa_data="$(mktemp -d)"
XDG_DATA_HOME="$qa_data" godot --headless --path . --script res://tests/persistence.gd -- --test-isolated --test-data-root="$qa_data"
```

The persistence test refuses to write unless Godot's actual data directory is inside the explicitly supplied disposable directory. It checks full save/reload, equipment reconstruction, backup recovery, invalid numeric and boolean fields, invalid inventory identifiers/upgrades/duplicate UIDs, and preservation of corrupted data. JSON parser errors from intentionally broken samples are expected; the final `PERSISTENCE RESULT` reports the result.

To capture real rendered previews, use an active graphical display or Xvfb. This check cannot use `--headless`:

```sh
godot --path . --resolution 1280x720 --script res://tests/capture_preview.gd -- --test-isolated --capture-dir=/absolute/path/to/previews
```

It saves the village, merchant, forge, inventory, combat, and a 1600 × 720 phone aspect preview. These captures use the actual project renderer and clear transient notifications before each screenshot.
