# Container A Log - IDOL Genesis

Status: active workflow keeper and implementation container for this session.
Repo: `ElKlient/IDOL-Genesis`
Branch: `main`
Base before this log: `dd4cd59 Add workflow first handoff note`

## Role

Container A owns the handoff discipline for this session:

- keep workflow knowledge in GitHub,
- preserve the user's Termux/Godot Android path,
- keep a local container log,
- push finished repo state to `main`,
- leave exact commands for the user and next containers.

## Scope Completed

- Added early medieval / stone-age atmosphere directly in the game scene.
- Kept the existing people mechanics, retargeter, procedural walk, work loop, and cargo handling.
- Added lightweight procedural settlement scenery in Godot instead of heavy imported environment packs.
- Documented Godot import/runtime verification.
- Documented the Termux update path for the user's phone.
- Added `WORKFLOW_FIRST.md` as the first-read notebook for future containers.
- Added this Container A log and the rule that future containers keep their own logs.

## Main Files Touched

- `scripts/main.gd`
- `project.godot`
- `README.txt`
- `WORKFLOW_FIRST.md`
- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/CONTAINER_HANDOFF_WALK_AND_IMPORT.md`
- `docs/NEXT_DEVELOPMENT_COORDINATION.md`
- `docs/container_logs/CONTAINER_A_LOG.md`

## Commits Pushed In This Chain

- `eb9ec9e Add ancient settlement atmosphere`
- `ddb9762 Add next development coordination brief`
- `7e9c6bf Add walk and import handoff report`
- `d57082c Document Godot verification path in handoff prompt`
- `ae030af Clarify Godot import verification in handoff prompt`
- `ccd4fba Document Termux update path in handoff prompt`
- `dd4cd59 Add workflow first handoff note`
- Current log commit: `Add container A workflow log` (check `git log` for final SHA)

## Godot Verification

Known working container binary:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64
```

Version checked:

```text
4.7.2.stable.official.ed1daf0bf
```

Working verification order:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit
timeout 8s /workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path .
```

Observed result:

- editor import passed,
- runtime load passed after import,
- 8 second startup test produced no runtime errors,
- timeout exit code is expected for the timed startup test.

## Termux Command For User

Paste this in Termux on the phone:

```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```

Expected:

- top commit is the newest workflow/container-log commit,
- below it should be `dd4cd59 Add workflow first handoff note`,
- the Godot Android app should open the same folder containing `project.godot`.

## Rules For Next Containers

- Read `WORKFLOW_FIRST.md` first.
- Then read the handoff docs listed there.
- Keep your own log under `docs/container_logs/`.
- Do not use `cd ~/IDOL-Genesis` for the user's Termux path.
- Do not delete `.godot` during a normal phone update.
- Do not use `git stash -u` during a normal phone update.
- Do not replace the people system unless the task explicitly requires it.
- Prefer lightweight procedural assets for Android unless a curated pack is clearly worth importing.
- If plain `git push` fails in the container, use the GitHub connector or Git data API with a fast-forward guard.
## Coordination Update - 2026-09-08

User confirmed Containers B, C, D and E are now analyzing the handoff prompt.

Active delegated lanes:

- Container B: people, walk realism, arm axes, skeleton/pose safety. Preserve current model unless the task explicitly changes people.
- Container C: settlement assets and visual environment. Prefer selected lightweight GLB/GLTF assets and mobile-safe wrappers.
- Container D: Android/Godot workflow, import speed, gray screen, build/runtime validation and Termux update flow.
- Container E: settlement gameplay, resources, buildings, tasks, UI and social/life systems.

Container A coordination rule:

- Do not merge or overwrite container work blindly.
- Wait for each container's log/report or inspect its pushed commit before integration.
- Integrate smallest safe verticals first: Android safety, then animation safety, then world visuals, then gameplay expansion.
- Keep documenting workflow changes in `WORKFLOW_FIRST.md` or this log so future containers start from repo knowledge, not chat memory.

## Instruction Update - 2026-09-08

Added mandatory post-analysis reporting instructions to:

- `WORKFLOW_FIRST.md`
- `docs/CONTAINER_HANDOFF_PROMPT.md`

New rule for helper containers:

- after analysis, each container must write its own log under `docs/container_logs/`,
- the log must include checked scope, important files/functions, changed files or no-code status, commit SHA, risks/tests, and the integration decision for Container A,
- Container A integrates in order D -> B -> C -> E and never merges blindly.

## Instruction Update - Container Tasks And 35 Minute Checks - 2026-09-08

Container A added dedicated task files for helper containers:

- `docs/container_tasks/README.md`
- `docs/container_tasks/CONTAINER_B_TASK.md`
- `docs/container_tasks/CONTAINER_C_TASK.md`
- `docs/container_tasks/CONTAINER_D_TASK.md`
- `docs/container_tasks/CONTAINER_E_TASK.md`

New standing instruction:

- active/waiting helper containers must check every 30 minutes for new Container A instructions,
- they must read `WORKFLOW_FIRST.md`, their own task file, and their own log,
- they may spawn subagents inside their lane,
- subagents do not own independent pushes to `main`; the parent container owns log/commit/push.

## Container A Patch - 0.8.20 Living World - 2026-09-08

Goal: merge the existing hunt/hides work with a stronger world-depth pass so the scene looks less empty and more like a living early settlement, while preserving the current people model, walking work from Container B, AI, retargeter, camera and Android target.

Sidecar agents called by Container A:

- B-sidecar confirmed not to touch people/bone functions during a world patch and to check obstacle/path impact.
- C-sidecar recommended more lived-in fire/camp details, work clusters, trampled ground and river/forest depth without importing whole packs.
- D-sidecar confirmed Godot 4.x with `gl_compatibility` remains the right engine path for this lightweight Android prototype.
- E-sidecar recommended a small hides/tanning direction; remote `0.8.19 Hunt and Hides` already implemented the first hunt loop, so Container A kept that as the gameplay source of hides.

Implemented in `scripts/main.gd`:

- bumped version title to `IDOL -- GENESIS 0.8.20 LIVING WORLD`,
- added `make_world_depth_pass(home_a, home_b)` after the existing ancient settlement pass,
- added palisade edge, river gate, home yards, bedrolls, firewood stacks, hide processing yard, river crossing stones, footprint marks and story stumps,
- preserved `ŁOWY`, `meat`, `hides`, `wildlife`, `assign_hunt(v)` and `finish_hunt(v)` from the remote hunt patch,
- added `hide_work_points` as future hook for tanning/crafting work points, but did not add a second hide generator,
- improved visible rolled hide cargo,
- kept HUD meat/hides/wildlife summary from the hunt patch.

Tasks distributed for next helper pass:

- Container B: verify walking/arms/cargo around the new palisade, hide yard, hunt targets and obstacles.
- Container C: prepare first tiny GLB promotion plan using only 4-6 selected assets.
- Container D: run Godot/Android import/runtime/performance validation after 0.8.20.
- Container E: review the `ŁOWY`/meat/hides loop and recommend the next gameplay vertical.

Integration rule stays: D first, then B, then C, then E.

Validation run by Container A:

- `git diff --check` passed.
- Godot binary found dynamically at `/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64`.
- `"$GODOT_BIN" --headless --editor --path . --quit` passed and imported assets.
- `"$GODOT_BIN" --headless --path . --quit` passed.
- `timeout 8s "$GODOT_BIN" --headless --path .` ran without errors until expected timeout.
- Godot generated `scripts/main.gd.uid` and `scripts/retargeter.gd.uid`; Container A removed them from this patch and did not stage them.

## Container A Patch - 0.8.21 Living Camp Props - 2026-09-08

Goal: keep the remote `0.8.20 Living World` procedural depth pass and add the first small active GLB prop set so the camp reads as a lived-in settlement on phone footage.

Implemented in `scripts/main.gd`:

- bumped version title to `IDOL -- GENESIS 0.8.21 LIVING CAMP PROPS`,
- kept `make_world_depth_pass(home_a, home_b)` from `0.8.20` and added `make_living_camp_props(home_a, home_b)` after it,
- added scene helper functions for lightweight imported props,
- added real Kenney props around the hearth, stockpile, tool yard, riverside and home edges,
- preserved people models, procedural walk, retargeter flag, AI orders, hunting and HUD logic.

Active assets added:

- `assets/environment/kenney_survival/`: wood, stone, axe, pickaxe, hammer, workbench, bedrolls, half tent, campfire pit and required `Textures/colormap.png`,
- `assets/environment/kenney_nature/`: canoe, paddle, log stack and large rock.

Validation run by Container A:

- `git diff --check` passed.
- Godot headless editor import passed after adding the missing survival colormap texture.
- Godot headless runtime start passed.
- 8 second headless startup ran clean until expected timeout.
- `.import` and `.uid` files stay ignored by repo policy.

## Container A Patch - 0.8.22 Textured Climate - 2026-09-08

Goal: make the current stone-age settlement feel less flat and closer to the realistic earthy reference direction without adding heavy texture packs or replacing the human model.

Plan split used for this pass:

- terrain/paths: procedural material noise plus dirt stains,
- wood/hides: warmer rough material texture from existing color palette,
- stone: rough speckled material texture,
- water: subtle procedural variation,
- atmosphere: light fog and warmer depth,
- Android: keep runtime texture size small and reuse the existing `world_count()` density scaling.

Implemented in `scripts/main.gd`:

- bumped version title to `IDOL -- GENESIS 0.8.22 TEXTURED CLIMATE`,
- added procedural textured material generation inside `mat(c)` for grass, earth, wood, stone and water,
- added cached small `NoiseTexture2D` materials instead of bitmap texture imports,
- added `make_surface_stain(...)` and `make_climate_surface_pass(home_a, home_b)`,
- added dirt, ash, trampled soil and muddy riverbank surface layers around the camp,
- added light background fog in `Environment`.

Preserved:

- people models, procedural walk, retargeter flag and AI,
- Android performance pass from Container D,
- active GLB props from `0.8.21`,
- hunting/meat/hides gameplay.

Validation completed in this local pass:

- `git diff --check`: clean
- Godot headless editor import: clean
- Godot headless runtime startup: clean
- 8 second headless startup: clean

## Container A Patch - 0.8.23 Realistic Visual Pass - 2026-09-08

Goal: move the running Android scene closer to the visual concept from the user's phone screenshot without replacing the human model, adding heavy assets, or forcing a slow `.godot` cache reset.

Implemented in `scripts/main.gd`:

- bumped version title to `IDOL -- GENESIS 0.8.23 REALISTIC VISUAL PASS`,
- changed the base atmosphere toward darker grass, warmer sunlight, lower washed-out fog and a more earthy settlement palette,
- deepened the river colors and added heavier muddy banks plus wet grass lips,
- added a new `make_realistic_visual_pass(home_a, home_b)` with two wooden crossings, bank bushes, reeds/grass/rocks, fallen logs, extra edge trees, stronger smoke and warm light pools,
- rebuilt the visual weight of houses with heavier timber, visible roof planes, roof strips, chimney blocks, smoke columns, warm door/window accents and trampled entrance soil,
- made the palisade denser and heavier with lower rails and ground shadow stains while preserving the gate gap,
- changed mobile UI panels from plain `ColorRect` overlays to dark glass `Panel` styles with warm borders, styled command buttons and matching joystick panels,
- disabled floating carried-resource visuals on settlers so strategic-camera footage no longer shows random objects sticking out of people.

Preserved:

- existing human model, skeleton, procedural walk and retargeter flag,
- AI orders, hunting/meat/hides loop, building flow and resource logic,
- Android-oriented procedural texture cache and `world_count()` density scaling.

Validation completed in this local pass:

- `git diff --check`: clean
- Godot headless editor import: clean
- Godot headless runtime startup: clean
- 8 second headless startup: clean until expected timeout

## Container A Patch - 0.8.24 Organic World Pass - 2026-09-09

Goal: respond to the user's Android screenshots showing that `0.8.23` still looked too much like a flat rectangular toy map and not enough like the visual concept.

Implemented in `scripts/main.gd`:

- bumped version title to `IDOL -- GENESIS 0.8.24 ORGANIC WORLD PASS`,
- added `mat_flat(c)` for custom flat meshes and reduced procedural primitive segment counts so cylinders/spheres read more low-poly and cost less,
- expanded the base ground plane from 68x68 to 96x96 and increased forest density around the edge of the playable view,
- replaced segmented rectangular river blocks with continuous ArrayMesh water and separate continuous muddy/wet-grass riverbank strips,
- changed ground patches and surface stains from boxes to low elliptical discs to remove the obvious square-tile look seen on Android screenshots,
- darkened terrain, tree crowns, grass, fog, sunlight and dynamic lighting so the image is earthier and less plastic,
- added tree-base shadows, central Idol plaza shadows, extra stones, poles and bushes to give the camp more grounded mass,
- tinted imported house meshes and muted roof/wall/door colors, with moss/dirt strips on roofs and less bright house lights,
- toned down the test memory flower, UI panel opacity/button colors and selected-person marker.

Preserved:

- people model, skeleton, procedural walk, retargeter flag and AI,
- resource/build/hunt gameplay,
- 0.8.23 hiding of floating carried-resource visuals.

Validation completed:

- `git diff --check`: clean
- Godot headless editor import: clean
- Godot headless runtime startup: clean
- 8 second headless startup: clean until expected timeout

Known limitation:

- local screenshot capture in this container is not reliable because Godot `--headless --write-movie` crashes inside the dummy renderer. Android screenshot/video remains the useful visual QA path for now.

## Container A Patch - 0.8.25 Grounded Settlement Pass - 2026-09-09

Goal: answer the user's direct feedback that the game still looked too artificial/flat on Android, and push helper containers B/C/D/E onto the current visual sprint instead of their older 0.8.20 tasks.

Implemented in `scripts/main.gd`:

- bumped version title to `IDOL -- GENESIS 0.8.25 GROUNDED SETTLEMENT PASS`,
- replaced the flat base `PlaneMesh` with a lightweight custom `ArrayMesh` terrain using subtle edge/river-aware height variation,
- expanded the viewed world with low background landforms, extra edge bushes and rocks so the camera sees a heavier horizon instead of an empty board edge,
- added soft alpha shadows under adults and children to visually attach settlers to the ground,
- added fuller leather/fur/cloth layers around settler torsos and sides without replacing the existing human model,
- moved the start camera slightly higher/wider and reduced FOV so the first Android frame reads more like a whole settlement,
- reduced HUD/panel/button/joystick opacity so the UI does not crush the world view as hard.

Documentation and coordination:

- updated `README.txt`, `WORKFLOW_FIRST.md`, `docs/CONTAINER_HANDOFF_PROMPT.md` and `project.godot` for 0.8.25,
- updated `docs/container_tasks/README.md`,
- added urgent 0.8.25 task sections for B/C/D/E:
  - B: verify people/walk with grounded shadows and clothing,
  - C: stop broad planning and target visible toy-looking environment pieces,
  - D: validate Android/Godot runtime/import/performance after terrain mesh and density changes,
  - E: reduce debug feel of HUD/presentation while preserving controls.

Preserved:

- current people model and skeleton,
- procedural walk and retargeter flag,
- AI/resource/build/hunt gameplay,
- active lightweight GLB prop set.

Validation completed:

- `git diff --check`: clean
- Godot headless editor import: clean
- Godot headless runtime startup: clean
- 8 second headless startup: clean until expected timeout

Known limitation:

- this container still relies on Android screenshots/video for final visual judgment; local headless Godot validates runtime but does not provide a trustworthy rendered phone screenshot.
