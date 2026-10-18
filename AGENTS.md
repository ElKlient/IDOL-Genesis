# Active project on `zelazny-swit`

This branch contains the separate mobile ARPG **Żelazny Świt** in
`games/zelazny-swit`. Read that project's `README.md` and
`docs/STRESZCZENIE.md` before editing it.

The root `WORKFLOW_FIRST.md`, root Godot project, and other existing assets
belong to the earlier IDOL Genesis game on `main`. They are historical context,
not instructions to replace the active project or change branches.
Do not edit the earlier games or calendars while working on Żelazny Świt.

Target Godot 4.4+ GDScript, Android landscape, Compatibility renderer. Prefer
original procedural models; preserve the current save schema and independent
project directory. Commit only reviewed task files, never caches or imports.
Never force-push, erase user data, or reset a phone checkout to update it.

Published changes go to `zelazny-swit`. Give the user short Polish instructions
and a ready Termux update command after checking engine startup and the relevant
integration tests. Test scripts require `--test-isolated`; persistence tests
also require an explicit temporary XDG_DATA_HOME path.
