# Current Person 2 continuation handoff

Updated 2026-11-15 in **Kiro** after diagnosing and fixing the reported flash
failure on top of checkpoint **70fe823**. The live spoken-to-game flash failure
was reproduced from the ignored run logs, root-caused, fixed and covered by a new
regression. This replaces the old accumulated handoff. Read
[project description](PROJECT_DESCRIPTION.md), [decisions](DECISIONS.md)
and [AGENTS.md](../AGENTS.md). Earlier records are in [history](ARCHIVE.md), not below.

Continuation is in **Kiro**. Use [the Kiro resume prompt](KIRO_RESUME_PROMPT.md)
and Kiro's native tools; historical Codex tool/sandbox instructions are environment-specific.

## Workspace and Git

- Checkout: `C:\Users\Isoto\Documents\GitHub\callout-trainer`.
- Branch/upstream: `person-2/model-capability-spike` / `origin/person-2/model-capability-spike`.
- Gameplay checkpoints: `2a33eda` GPU + live mic; `156c581` voice/game bridge;
  `608cae7` plant-start seven-region adaptation with first-known enemy arrivals.
- User-authorized map integration: main fetched at `8712f7d` (already included);
  actual new map was `person-3/greybox-b-site` at `76b8eaa`, merged at `513b2e9`.
  Existing edits were checkpointed first at `86a54aa`. No merge into main.
- Newer documentation commits may follow. Inspect status/log before acting. The
  implementation checkpoint was clean and pushed; never assume a new window is clean.
- PR #4 is already merged. This current branch is not merged into main. Do not resume
  obsolete `person-2/bot-perception`, discard teammate edits or merge main blindly.

The user made the six-hour final-sprint handoff at Person 3 `4c85f39` authoritative:
Person 1 left; Person 2 owns the GPU PC, model/STT runtime and inherited world/engine work.
Person 3 supplies non-GPU components/support. The six hours was the starting budget,
not a fresh timer now. Latest user rule: plant is t0; spawn unknown enemies only at
their first known annotation positions.

## Resolved blocker: far-zone flash failed in play — diagnosed and fixed

**The live playtest failure is reproduced and fixed.** The user reported the flash
still not fully functional after `29ba6d7`. Tracing the ignored
`runs/voice-game-20261115-061835` logs showed two spoken "flash" rounds:

- Round 1, "Flash C link": model interpreted `throw_flash/c_link/now` correctly;
  the command was accepted and completed (it walked because the ally's own scripted
  C Link smoke, released at tick 249, legitimately occluded the zone — working as
  designed, though the walk can surprise a player).
- Round 2, "Flash B heaven": model interpreted `throw_flash/b_heaven/now` correctly,
  the command was **accepted at tick 751 then `failed / execution_failed` at tick 763
  without the teammate moving or throwing**. This is the real bug.

Root cause, in `bots/visible_flash_controller.gd::prepare_visible`: after turning
toward the zone it classified the standing spot into throw-in-place (an aim point
visible and within 20 m), occluded (walk), or **visible-but-out-of-range (terminal
`failed`)**. When the teammate was not at Pit (the annotated baseline had moved it
to Cubby by the time the player spoke), every B Heaven aim point was either occluded
or 21–33 m away — past the 20 m range. The controller returned a terminal
`visible_zone_out_of_throw_range`, so the command failed instantly instead of
walking closer. Measured from Cubby: six B Heaven points occluded, the three clear
ones at 33.4/34.6/32.4 m; the near points come into range only after approaching.

Fix: a far-but-reachable zone now authorizes walking, exactly like the occluded
case. `prepare_visible` returns `blocked` (reason `flash_zone_visible_out_of_range`
or `flash_zone_occluded`) instead of `failed`. `motion_controller._advance_visible_flash`
already walks toward the zone's static fallback marker, re-checks LOS and range every
tick, and throws at the first in-range visible point; it still fails honestly
(`flash_zone_still_occluded` / `no_reachable_flash_viewpoint`) only when navigation
cannot get any closer. Throw-in-place for a visible in-range zone is unchanged.

Required behavior now holds: "flash C link" turns toward C Link, throws from the
current spot if an aim point is visible within range, and walks only when it cannot
yet throw — whether the zone is occluded or simply too far — stopping and throwing
the instant visibility and range open. "Flash … on my cue" still prepares and waits.
There is no spoken teammate molly command; scripted enemy grenade/molly use is separate.

Not yet confirmed: a fresh human microphone-to-game playthrough of the fixed far-zone
flash. The reproduction and fix are verified in the headless site scene through the
real voice bridge and executor path, not by a new live mic session.

## Implementation present (acceptance limits below)

User-requested flash behavior: current site supplies one extra teammate flash per
round and targets for all seven zones. `bots/visible_flash_controller.gd` turns
first, checks static zone-point world/smoke LOS, and throws from the current spot
when an aim point is visible and within 20 m. When it cannot yet throw — the zone is
occluded, or every visible point is out of range from the current spot — it walks
toward the zone's static fallback marker, re-checking visibility and range every tick,
and throws at the first in-range visible point. It fails honestly only when navigation
cannot get any closer. Immediate flashes stage physically before commit; on-cue
flashes wait for release; cancelling during visibility seeking retains the charge.
The bridge preserves an explicit flash action instead of accepting a mistaken swing.
No spoken teammate molly command exists. This extra flash is an authored user-requested
extension, not recorded Omen inventory. Shared comms schema is unchanged.

User-requested rifle tuning: 40 body damage, 160 head damage (4x multiplier),
shared by player and bots. The integration runner overlays local `weapons/weapon.gd`
so the pinned shared-source snapshot uses these values too.
Sandboxed Godot startup cannot read the Windows certificate store; the same existing
runner succeeds with approved execution outside that sandbox. Keep strict error checks.

**Voice path:** Windows default Razer microphone -> local Whisper small.en CUDA/float16
-> Person 3 grounded Llama 3.1 8B interpreter -> localhost proposal -> Godot-stamped
receipt tick -> existing 18-tick delayed inbox -> beliefs/planner -> shared physics.
V is PTT and B is dash in voice scenes (no overlapping V/dash binding); raw mic audio stays in memory. Logs are local under `runs/`.
Swing/go/cancel fast path retains readiness/delivery validation. Preparation phrases
such as "get ready to swing" are forced to `on_cue` at the engine bridge, even
if the model proposes immediate execution; they stage and wait for a separate
"swing"/"go". Actual normalization is recorded with a `timing_guard` marker. Round sessions reject stale
speech/model replies; retries deduplicate; disconnect/invalid goals retain safe control.

**Selected AI scope:** LLM interprets, deterministic planner selects goals. This is the
final-sprint handoff's capability-driven fallback. Full LLM goal tests missed the existing
two-second context window and remain unaccepted. `-ModelGoals` is experimental. Do not
claim it works, silently enable it, relax expiry or turn its failing fixture into a pass.

**Scenario:** `validation/run_voice_game.ps1` now defaults to Person 3's seven-zone
`world/maps/b_site.json` at `76b8eaa`. `-Lotus` is a compatibility alias for the
new default, not the old geometry. `-LegacyRoom` and `-LegacyLotus` retain old
profiles. `world/site_builder.gd` preserves source geometry/zones and adapts only
plant/spawn metadata; `scenarios/site_coverage.json` supplies new physical anchors.
Circular Pit and Upper precedence match the imported minimap and coordinate HUD.
The player takes Something/Yoru's role; ally takes f0rsakeN/Omen's role; PRX holds the
plant. Unknown FNC starts have no actor/collider/weapon at t0. At +23s/tick 1380:

| Actor | First known position |
|---|---|
| Chronicle / crashies | b_heaven |
| kaajak | c_link |
| Boaster | b_main |

The +16s Boaster smoke does not locate him. He is first localized by a recorded death;
spawning him alive there is explicitly an authored continuation. Never force the source
kills/result. Preserve all four `start_region: "unknown"` values. Metric coordinates,
geometry and within-region placements are authored, not independently verified pro data.
Person 3 source title/channel/event/year/named annotator/team review are still unresolved.

Late sensor registration emits no testimony and preserves pending evidence. Shared
movement/rifles/damage/utility/defuse execute ordinary physics; player cannot self-defuse
the PRX plant. A delayed own sight in Heaven can trigger the authored A-Link flank.
Round elimination/defuse/detonation and restart are implemented. The annotated bot
baseline now runs through `bots/annotation_policy.gd` and
`bots/annotation_executor.gd`: ally movement/smokes, remote Boaster smoke, private
crashies recon and kaajak grenade adaptation. Delivered player calls/accepted
commands, own damage or delivered off-baseline sightings hand control to the
reactive planner. See `bots/LOTUS_SCENARIO.md` for physical timing and kit limits.
Enemies cannot shoot while blind, show a white head circle, and all dead bots
disappear with collision disabled. Exact agent kits/continuous reenactment remain
approximations. HP+armor is a simplified shared pool.

## Important files

| Area | Paths |
|---|---|
| Live setup / launch | `validation/run_live_voice.ps1`, `validation/run_voice_game.ps1`, `bots/live_voice.py`, `bots/voice_host.py` |
| Bridge / scene | `scenes/bots/voice_bridge.gd`, `voice_playtest.gd`, `lotus_playtest.gd` and matching scenes |
| Runtime / fair sensing | `bots/teammate_runtime.gd`, planner/motion/combat modules; `perception/scene_sensor.gd`, inbox/kernel |
| Current world | `world/site_builder.gd`, `world/maps/b_site.json`, `scenarios/site_coverage.json`, `scenes/bots/site_playtest.gd` |
| Source/runtime data | `scenarios/fnc_prx_lotus_toronto2024_gf.json`, `lotus_b_coverage.json`, `first_known_spawns.gd` |
| Adapted policy | `bots/annotation_policy.gd`, `bots/annotation_executor.gd`, `bots/retake_policy.gd` (policy uses copied delayed evidence/own state; executor owns physical utility) |
| Checks | `validation/run_person2_tests.py`, `check_lotus.py`, `run_voice_model_smoke.py`, `audit_voice_run.py`, `tests/person2/` |

Component guides: [current scenario](../bots/SITE_SCENARIO.md), [legacy baseline detail](../bots/LOTUS_SCENARIO.md), [bridge](../bots/VOICE_GAME.md),
[standalone mic](../bots/LIVE_VOICE.md), [spike results](CAPABILITY_SPIKE.md),
[perception](../perception/README.md). No shared comms/observation/belief schema was
silently changed by the bridge/scenario work. New registration/scenario-policy/transport
seams are internal Person 2 integration APIs.

## Dependencies — do not blindly upgrade one side

- Python interpreter/vocabulary/recorder source: read-only Person 3 **b84cc93** snapshot.
  The launcher recreates it from Git when missing. It is not necessarily imported as
  normal modules into this checkout. Do not build a competing interpreter.
- Running Godot belief dependency: **57f809d**, with the current planner's inert `trust`
  compatibility key. Person 3's newer snapshot/schema removal at `d69db0f` and approved
  `person-3/drop-trust-planner` change (`4a0fb4d`) must be reviewed/tested **together**.
  Updating only `--person3-ref` to b84cc93 will conflict with the current planner shape.
- Working-belief hedge/full-acceptance behavior is a separate known gap, not fixed by
  deleting a field. Fully accept valid player testimony without credibility/history.
- Person 3's Python headless pipeline applies at future ticks immediately for fixtures;
  do not use that mirror as a live clock. Godot owns actual receipt/delivery timing.
- Default launcher freezes map/shared game source **76b8eaa**, keeps belief **57f809d**,
  and overlays local bot integration and approved mechanics. Legacy profiles retain
  shared source **8712f7d**. Dependency refs are printed; do not advance belief alone.

## Installed tools and commands

Configured PC: Ryzen 7 7700, RTX 4060 Ti 16GB, approximately 32GB RAM. Ollama 0.40.16;
Llama 3.1 8B Q4_K_M. Qwen 2.5 3B was only an experimental research-license evaluation,
not a default/shipped requirement. Models are downloaded/cached outside Git, not trained.

PowerShell launch (close any earlier voice-host console first):

```powershell
cd "C:\Users\Isoto\Documents\GitHub\callout-trainer"
.\validation\run_voice_game.ps1
```

F restarts at plant, V talks, B dashes, Esc releases the mouse. Legacy profiles:
pass `-LegacyRoom` or `-LegacyLotus`. Do not replace this launcher with running root `project.godot` directly;
its main scene is still the original scaffold, not the integrated voice scenario.

Validation variables:

```powershell
$pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$voicePython = "$env:USERPROFILE\.cache\callout-voice-venv\Scripts\python.exe"
$godotExe = "$env:USERPROFILE\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe"
$sourceRoot = "$env:TEMP\callout-voice-integration-b84cc93\source"
& $pythonExe tools/check_repo.py
git diff --check
& $pythonExe validation/check_lotus.py
& $voicePython -m pytest tests/person2/test_lotus_authoring.py tests/person2/test_voice_host.py -q
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 76b8eaa --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --site-smoke --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --perception-smoke --person1-ref 8712f7d --person3-ref 57f809d
```

Choose relevant checks for the actual change; do not rerun all engines for docs edits.
For real-model bridge regression, use `validation/run_voice_model_smoke.py` with
`--godot`, `--source-root` and **`--interpret-only`**. Omitting that flag selects the
unaccepted full-goal experiment, not an ordinary passing regression. Keep its failures honest.

## Actual evidence and limits

- Flash far-zone fix (Kiro, this window): the live `runs/voice-game-20261115-061835`
  round-2 "Flash B heaven" `execution_failed` is reproduced in the headless site
  scene through the real voice bridge and executor. With the teammate standing at
  Cubby, every B Heaven aim point is occluded or 32–35 m away; the old controller
  returned a terminal out-of-range failure and did not move. After the fix it walks
  into range and throws. New regression `_test_far_zone_flash_walks` in
  `tests/person2/site_smoke.gd` asserts release, no `execution_failed`-without-moving,
  physical repositioning and a throw before reaching the zone center. **Site smoke
  now passes 40 checks** (was 36) on `76b8eaa` / belief `57f809d`. Reverting the
  one-line controller change makes exactly the two new far-zone assertions fail,
  confirming the regression is meaningful. Required bot suite still passes **575**;
  flash unit tests **12**, lotus authoring/voice **7** Python tests pass. No new
  human microphone acceptance of the fixed far-zone flash is claimed.

- Flash update (prior, 29ba6d7): 36 synthetic current-map checks and 575 required bot
  assertions passed, but the user reported the flash still not fully functional —
  resolved above. The unchanged local Llama interpreter returned `throw_flash/c_link/now`
  and `throw_flash/b_heaven/now` for the two logged typed/spoken samples; interpretation
  was never the failing stage. Controller uses only own pose/static zone affordances/
  world-smoke occlusion, not enemy truth.

- Preparation/cue fix: real TCP voice regression passes **35 checks** using shared
  source `8712f7d` / belief `57f809d`. A deliberately incorrect `now` proposal for
  "get ready to swing" becomes `on_cue`, physically stages, waits 60 ticks, and
  moves only after a separate swing cue. Preparatory paraphrases and unchanged
  explicit "swing now" detection are checked. This is a synthetic socket test,
  not a fresh human/model speech acceptance claim. Same bridge serves current map.

- Current imported-map integration: **36 functional checks** pass on `76b8eaa` / belief
  `57f809d`, including visibility-first flashes, cancellation, inventory and cues.
  The earlier **24 rendered checks** preceded the flash update; capture inspected.
  Source walls/zones, seven navigation anchors, circular Pit/Upper precedence,
  real staged smoke, first-known arrivals, flash/no-fire/head circle, death/reset pass.
  Required bot regression also passes **575** with shared source **76b8eaa** and
  belief **57f809d**; seven Python tests and PowerShell launcher syntax pass.
  The map uses a four-second utility staging grace
  for physical scale; model/message expiries are unchanged. This is not human voice
  acceptance. Prior 53-check custom-Lotus results below are the legacy profile.

- Five standalone human microphone calls confirmed: all five semantic results correct,
  cue -> queue spelling error, median STT 0.138s / after-release total 0.718s.
- Standalone interpreter smoke: eight semantic samples correct, warm median 0.590s;
  most were prompt examples, not a general accuracy study. Use 127.0.0.1, not localhost,
  on this PC. Initial model load took 44.52s; warm before starting the round.
- Real-model typed three-region engine fixture passes interpretation, actual delayed
  report and physical movement. That run's interpretation took 2.282s under engine load.
  Scoped audit passes 33 contexts, 28 changed decisions, 157 deliveries, one model record.
- Current local bot continuation: **575 default/cross-lane assertions** pass,
  including 21 annotation-baseline and 46 combat checks; **139 live-perception**
  checks and **seven Python** authoring/voice-boundary tests pass.
- Final **53-check Lotus scene** passes: physical ally smokes/staging, enemy private
  recon, grenade ignition/landing in Pit, recon wall/smoke guards, no fire during a
  real flash, head-circle visibility/expiry, dead bot hiding/collision removal,
  elimination/reset and V/dash separation. The scenario clock is fast-forwarded
  for beat checks; this is not a human real-time playthrough.
- Rendered **46-check** intermediate run passed; inspected the saved white head
  circle. It preceded the added recon/grenade boundary and V/dash assertions.
  Captures are local temporary artifacts, not committed assets.
- Navigation-bake and ObjectDB-at-exit warnings remain in the scene fixture;
  strict script/engine ERROR checks pass. Sandboxed startup's certificate-store
  error is avoided by approved test execution outside the sandbox, not by filtering it.
- Existing FPS and TCP checkpoints: 41 and 22 checks respectively. Do not sum historical
  runs into a fresh claim. Known navigation-bake GPU readback warning remains.

No confirmed human voice-to-Lotus test, exported-build acceptance, OS-network-disabled
test, backup video, full-game/model fairness or training-benefit result exists. The
scenario fixture fast-forwards its authoring clock for +23s checks; normal gameplay
waits real time. A guarded test health pool is fixture-only and resets to normal values.

## Next work, in order

1. The user-reported flash failure is diagnosed and fixed (far-but-reachable zones
   now walk into range instead of failing in place; see the resolved-blocker section).
   Remaining: confirm it with a fresh human microphone-to-game playthrough, and watch
   for the related case where the ally's own scripted C Link smoke occludes C Link and
   the teammate walks — correct behavior, but it can surprise a player. Preserve the
   visibility-first throw-in-place path and the honest no-reachable-viewpoint failure.
2. Coordinate the paired belief/planner schema removal and full player-report acceptance;
   test both consumers. Preserve valid uncertainty and actual delivery clocks.
3. Human-check the implemented annotation baseline and reactive transitions,
   especially spoken call overrides, physical staging and generic utility mappings.
   Keep player movement human-controlled and kills unforced.
   Preserve the user-selected first-known spawn rule and original map.
4. Close real acceptance gaps: fairness/safety coverage, offline/export test, backup
   video and demo rehearsal. Do not prioritize deferred grading/debrief/evaluation.

Maintain one current handoff and honest component guides. Push reviewable work on the
current branch; do not merge main or edit Person 3 code unilaterally. Source metadata,
pro fidelity, model licensing and measured results must remain explicitly qualified.
