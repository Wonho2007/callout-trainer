# Prompt for the next Kiro window

Paste this into a fresh Kiro window with repository access:

```text
Continue development in Kiro as Person 2 in:
C:\Users\Isoto\Documents\GitHub\callout-trainer
Branch: person-2/model-capability-spike

Latest adaptation: voice scenario now pins shared source 0260f28, with elevated
Heaven/Upper, deep Pit anchors, extended Pit volume and one scenario-only Upper
access ramp. Navigation bakes synchronized CSG collision. The source map JSON is
unchanged. Read the current handoff for the newest results before older notes.
Do not switch the launcher back to 76b8eaa. No remote push without a new explicit
user instruction.
Latest gameplay commit: 29ba6d7
Project handoff checkpoint: 4f98952 (newer documentation commits may follow)
Repository: https://github.com/Wonho2007/callout-trainer

Use Kiro's available terminal, file-editing and approval tools. References to
Codex tools or sandbox permissions in repository history are environment-specific;
do not assume those tools exist in Kiro.

Inspect git status and recent commits; preserve existing edits. Read AGENTS.md,
README.md, docs/PROJECT_DESCRIPTION.md, docs/PERSON2_HANDOFF.md, docs/DECISIONS.md,
docs/TEAM.md, docs/CONTRACTS.md, bots/SITE_SCENARIO.md and bots/VOICE_GAME.md.
Use docs/PERSON2_HANDOFF.md as the single current handoff. Do not follow retired
handoffs, restart completed setup, overwrite teammate work, reset/clean, blindly
merge, or merge this branch into main.

IMMEDIATE TASK: the far-zone flash failure the user hit is diagnosed and fixed
(a far-but-reachable zone now walks into range and throws instead of failing in
place; see docs/PERSON2_HANDOFF.md). The next step is human acceptance: launch
the game and confirm by microphone that "flash b heaven" / "flash c link" from the
plant hold turns, approaches when needed, and throws. Automated passes are NOT
human acceptance. If a new failure appears, trace the actual failing stage from the
ignored runs/voice-game-* logs rather than guessing.

Required: "flash c link" turns the teammate toward C Link, checks visibility,
and throws from its current spot if a point is visible within physical throw limits.
When it cannot yet throw (the zone is occluded, or every visible point is out of
range from the current spot) it walks toward the zone and throws as soon as a point
opens in range, failing honestly only when navigation cannot get closer. The
implementation provides one extra teammate flash per round, seven authored zone
targets, world/smoke LOS checks, 20m range, static sample points, on-cue preparation
and cancellation before release.
This extra flash is a user-requested prototype addition, not recorded Omen inventory.
There is NO teammate molly voice command; scripted enemy grenade/molly use is separate.

Trace the latest ignored runs/voice-game-* logs locally: transcript, exact model
prompt/raw output, bridge message, acceptance/readiness/execution, motion/LOS,
flash inventory and projectile creation. Confirm a freshly launched disposable
project is running. Key code:
- bots/visible_flash_controller.gd, flash_controller.gd, motion_controller.gd,
  command_executor.gd, teammate_runtime.gd
- scenes/bots/voice_bridge.gd, site_playtest.gd
- bots/voice_host.py, scenarios/site_coverage.json, utility/flash.gd

Project: a first-person voice communication practice game. Godot 4.4.1 stable,
GDScript, Compatibility renderer. Local Whisper small.en CUDA transcribes speech;
local Llama 3.1 8B interprets it; Godot stamps receipt, imposes 18 ticks of delivery
delay, and deterministic bot planners/shared physics execute it. Selected scope is
LLM INTERPRETS, DETERMINISTIC PLANNER DECIDES. -ModelGoals remains experimental
and unaccepted after latency/validity failures. Do not enable it or relax expiry
for passing tests. Models/environments are installed; no download/training needed.

Default map: Person 3's seven-zone world/maps/b_site.json from 76b8eaa on
person-3/greybox-b-site, merged at 513b2e9; integration 47846f8. Main was fetched
but still at 8712f7d: the map was on that teammate branch. Do not revert to the old
custom Lotus map. world/site_builder.gd preserves imported geometry/zones and
adapts plant/spawn metadata; scenarios/site_coverage.json maps bot anchors.
Circular Pit and Upper overlap use Upper precedence, matching the minimap.

Start at plant: human in Heaven, ally/spike in Pit. Unknown enemies have no actors
or colliders before their first-known +23s positions: Chronicle/crashies Heaven,
kaajak C Link, Boaster B Main. His earlier remote smoke does not locate him; his
alive continuation at a recorded-death location is explicitly authored. Never force
source kills/results or automate human movement. Bots follow annotated movement/
utility beats until delivered calls, observed deviations or own damage cause changes.
Exact kits, metric placements and continuous trajectories remain approximate.

Preserve other requested behavior:
- "Get ready to swing" prepares and waits; a separate "swing"/"go" releases it.
  Engine-side timing guard at 32b427c prevents an incorrect immediate model proposal.
- Rifle damage: 40 body / 160 head for player and bots.
- V push-to-talk; B dash; F restart; Esc releases mouse.
- Flashed enemies cannot shoot and show a white head circle.
- Dead enemy/teammate bots disappear and lose collision.

Policy/model inputs must remain copied delivered observations, local beliefs,
allowed own-state and static affordances. No live enemy Nodes/hidden transforms,
truth scene-tree lookups or player-only minimap/recon. Privileged physical adapters
may access geometry but must not leak hidden enemy state. Valid delivered player
reports are accepted even when wrong; no credibility/history system. The pinned
belief has a known full-acceptance/hedge gap; do not claim that fixed.

Dependencies: shared/map source 76b8eaa; Godot belief 57f809d with the current
planner's inert trust compatibility field; read-only Python Person 3 modules from
b84cc93. Do not upgrade belief alone: paired belief/planner changes require review.
Person 1 left; Person 2 owns this PC/runtime, bots, world/engine integration.
Person 3 supplies non-GPU interpretation/beliefs/logging/annotation. Preserve their
checkouts. The old six-hour sprint budget is historical, not a new deadline.

Launch after closing old game/voice-host windows:
  .\validation\run_voice_game.ps1
This defaults to the imported map; -Lotus is a compatibility alias. -LegacyRoom /
-LegacyLotus explicitly select older profiles. Root project.godot is the authoring
scaffold, not the integrated voice game. Installed paths and exact check commands
are in the current handoff; use pinned Godot 4.4.1. Ollama is at 127.0.0.1:11434.

Actual evidence: the far-zone flash fix makes site smoke pass **40 checks** (was 36)
on 76b8eaa / belief 57f809d; reverting the one-line controller change fails exactly
the two new far-zone assertions. The required bot suite passes 575, flash unit tests
12, and the 7 Python authoring/voice tests pass. The local Llama interpreter returned
throw_flash/c_link/now and throw_flash/b_heaven/now for the logged samples;
interpretation was never the failing stage. No fresh human flash acceptance,
full-game fairness, offline/export acceptance or training benefit is established.
Sandbox Godot may need approved execution outside the sandbox for Windows
certificate-store access; never filter errors/extend timeouts.

Confirm the fix by human microphone play, then close the remaining acceptance gaps
(see the handoff's Next work). Keep regressions meaningful and the handoff honest.
Preserve the map and other work. Commit/push this branch; do not merge into main.
Grading/debrief/evaluation remain deferred.
```
