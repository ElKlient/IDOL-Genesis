# Container B Log - People And Animation

## 2026-09-08

Role: Container B, scoped to people, skeleton axes, procedural walk, retargeter safety, body proportions, and naturalness of villager motion.

Base read:
- GitHub repo: `ElKlient/IDOL-Genesis`
- Branch: `main`
- Base commit before this update: `e01ac660774592dd27418dd85ebeec2e2ead5ad4`
- Current game version read from `project.godot`: `IDOL Genesis 0.8.18 Ancient Settlement`

Files read first:
- `WORKFLOW_FIRST.md`
- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/container_logs/CONTAINER_A_LOG.md`
- `docs/CONTAINER_HANDOFF_WALK_AND_IMPORT.md`
- `docs/NEXT_DEVELOPMENT_COORDINATION.md`
- `project.godot`
- `main.tscn`
- `scripts/main.gd`
- `scripts/retargeter.gd`
- `assets/third_party_model_packs/README.md`

Important workflow note:
- Local checkout `/workspace/scratch/3a13918d6208/IDOL-Genesis` was an old divergent 0.6.7 Armory prototype and must not be used as the base for current main.
- Plain CLI push failed because HTTPS credentials were unavailable.
- This update was prepared against live GitHub `main` and written with a fast-forward Git Data API update.

Findings:
- The current 0.8.18 main already keeps `USE_RETARGETED_ANIMATIONS=false`; active villager motion is the procedural bone layer in `scripts/main.gd`.
- Arm axis work from 0.8.16 is present: `pose_walk_arm` aims the upper arm using the child-bone axis instead of spinning the arm around its own long axis.
- The walk cycle from 0.8.17 is present: pelvis, spine, feet, toes, and knees already have procedural stride work.
- The retargeter is currently inactive, but if it is enabled later it still should not copy source position/scale tracks onto the villager skeleton, because that can overwrite model proportions.

Changes made:
- `scripts/main.gd`
  - Tuned walking arm swing to be slightly less exaggerated.
  - Added forearm follow-through and small wrist counterbalance so arms do not look locked below the shoulder.
  - Reduced arm and shoulder swing while a villager carries visible cargo.
- `scripts/retargeter.gd`
  - Strips position and scale tracks from retargeted clips before redirecting bones.
  - Keeps upper-body tracks removed for the existing procedural pose layer.
  - Leaves retargeter manual playback behavior intact.

Verification:
- Generated contents passed a trailing-whitespace check equivalent to the important part of `git diff --check`.
- Godot headless import/runtime could not be run in this container because the documented binary path `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64` does not exist here and no matching binary was found under `/workspace`.

Next steps for Container A or another animation pass:
- Pull latest `main`, then run the documented Godot import/runtime checks where the Godot binary exists.
- Ask the user for another short phone video focused on walking villagers with and without cargo.
- If the walk still looks stiff, next B pass should tune `pose_walk_leg` foot locking/stance timing, not replace the people model.

Termux update command for the user:
```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```
