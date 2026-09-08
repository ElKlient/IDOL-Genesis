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


## 2026-09-08 - GitHub Instruction Check

Trigger:
- User said: "Masz zapisane instrukcje na github zastosuj się".

Checked on current `main`:
- `WORKFLOW_FIRST.md`
- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/container_tasks/README.md`
- `docs/container_tasks/CONTAINER_B_TASK.md`
- `docs/container_logs/CONTAINER_A_LOG.md`
- `docs/container_logs/CONTAINER_B_LOG.md`
- `docs/container_logs/CONTAINER_C_LOG.md`
- `scripts/main.gd` focus ranges around people, pose, walk, and process functions
- `scripts/retargeter.gd`

Current instruction status for Container B:
- Scope remains people, walking animation, arm motion, bone axes, skeleton/pose safety.
- Do not touch terrain, resources, UI, asset packs, Android workflow, or gameplay balance.
- Existing B code pass is already on GitHub as `f0e7ea7 Tune villager walk animation`.

Decision:
- No extra code change in this check. The current B task should go to Android visual testing before another animation tweak.
- Recommendation to Container A: integrate/keep `f0e7ea7`, then request a short phone video focused on walking settlers with and without cargo.

35 minute instruction note:
- The repo asks active helper containers to check every 35 minutes.
- This host cannot honestly wake the same live coding session every 35 minutes by itself.
- Work Mode automations have a minimum practical frequency of once per hour, so exact 35-minute polling cannot be scheduled here.
- If the user resumes this container, re-check `WORKFLOW_FIRST.md`, `docs/container_tasks/CONTAINER_B_TASK.md`, and this log before doing more work.
