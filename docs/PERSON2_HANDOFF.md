# Current Person 2 continuation handoff

Updated 2026-11-15 after gameplay checkpoint **608cae7**. This replaces the old
accumulated handoff. Read [project description](PROJECT_DESCRIPTION.md), [decisions](DECISIONS.md)
and [AGENTS.md](../AGENTS.md). Earlier records are in [history](ARCHIVE.md), not below.

## Workspace and Git

- Checkout: `C:\Users\Isoto\Documents\GitHub\callout-trainer`.
- Branch/upstream: `person-2/model-capability-spike` / `origin/person-2/model-capability-spike`.
- Gameplay checkpoints: `2a33eda` GPU + live mic; `156c581` voice/game bridge;
  `608cae7` plant-start seven-region adaptation with first-known enemy arrivals.
- Newer documentation commits may follow. Inspect status/log before acting. The
  implementation checkpoint was clean and pushed; never assume a new window is clean.
- PR #4 is already merged. This current branch is not merged into main. Do not resume
  obsolete `person-2/bot-perception`, discard teammate edits or merge main blindly.

The user made the six-hour final-sprint handoff at Person 3 `4c85f39` authoritative:
Person 1 left; Person 2 owns the GPU PC, model/STT runtime and inherited world/engine work.
Person 3 supplies non-GPU components/support. The six hours was the starting budget,
not a fresh timer now. Latest user rule: plant is t0; spawn unknown enemies only at
their first known annotation positions.

## What works now

**Voice path:** Windows default Razer microphone -> local Whisper small.en CUDA/float16
-> Person 3 grounded Llama 3.1 8B interpreter -> localhost proposal -> Godot-stamped
receipt tick -> existing 18-tick delayed inbox -> beliefs/planner -> shared physics.
Right Ctrl is PTT; raw mic audio stays in memory. Logs are local under `runs/`.
Go/cancel fast path retains readiness/delivery validation. Round sessions reject stale
speech/model replies; retries deduplicate; disconnect/invalid goals retain safe control.

**Selected AI scope:** LLM interprets, deterministic planner selects goals. This is the
final-sprint handoff's capability-driven fallback. Full LLM goal tests missed the existing
two-second context window and remain unaccepted. `-ModelGoals` is experimental. Do not
claim it works, silently enable it, relax expiry or turn its failing fixture into a pass.

**Scenario:** `validation/run_voice_game.ps1 -Lotus` selects the separate authored
seven-region approximation. Original three-region map/root scaffold remain unchanged.
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
Round elimination/defuse/detonation and restart are implemented. Exact ally/utility/
cooldown baseline reenactment is **not** complete. HP+armor is a simplified shared pool.

## Important files

| Area | Paths |
|---|---|
| Live setup / launch | `validation/run_live_voice.ps1`, `validation/run_voice_game.ps1`, `bots/live_voice.py`, `bots/voice_host.py` |
| Bridge / scene | `scenes/bots/voice_bridge.gd`, `voice_playtest.gd`, `lotus_playtest.gd` and matching scenes |
| Runtime / fair sensing | `bots/teammate_runtime.gd`, planner/motion/combat modules; `perception/scene_sensor.gd`, inbox/kernel |
| New world | `world/lotus_builder.gd`, `world/maps/lotus_b_adaptation.json` |
| Source/runtime data | `scenarios/fnc_prx_lotus_toronto2024_gf.json`, `lotus_b_coverage.json`, `first_known_spawns.gd` |
| Adapted policy | `bots/retake_policy.gd` (copied delayed evidence and own state only) |
| Checks | `validation/run_person2_tests.py`, `check_lotus.py`, `run_voice_model_smoke.py`, `audit_voice_run.py`, `tests/person2/` |

Component guides: [scenario](../bots/LOTUS_SCENARIO.md), [bridge](../bots/VOICE_GAME.md),
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
- Launcher freezes shared game source **8712f7d** and overlays owned integration plus
  the previously approved local shared wave/player correction. It prints dependency refs.

## Installed tools and commands

Configured PC: Ryzen 7 7700, RTX 4060 Ti 16GB, approximately 32GB RAM. Ollama 0.40.16;
Llama 3.1 8B Q4_K_M. Qwen 2.5 3B was only an experimental research-license evaluation,
not a default/shipped requirement. Models are downloaded/cached outside Git, not trained.

PowerShell launch (close any earlier voice-host console first):

```powershell
cd "C:\Users\Isoto\Documents\GitHub\callout-trainer"
.\validation\run_voice_game.ps1 -Lotus
```

F restarts at plant, Right Ctrl talks, Esc releases the mouse. Original profile:
omit `-Lotus`. Do not replace this launcher with running root `project.godot` directly;
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
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 8712f7d --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --lotus-smoke --person1-ref 8712f7d --person3-ref 57f809d
& $pythonExe validation/run_person2_tests.py --godot $godotExe --perception-smoke --person1-ref 8712f7d --person3-ref 57f809d
```

Choose relevant checks for the actual change; do not rerun all engines for docs edits.
For real-model bridge regression, use `validation/run_voice_model_smoke.py` with
`--godot`, `--source-root` and **`--interpret-only`**. Omitting that flag selects the
unaccepted full-goal experiment, not an ordinary passing regression. Keep its failures honest.

## Actual evidence and limits

- Five standalone human microphone calls confirmed: all five semantic results correct,
  cue -> queue spelling error, median STT 0.138s / after-release total 0.718s.
- Standalone interpreter smoke: eight semantic samples correct, warm median 0.590s;
  most were prompt examples, not a general accuracy study. Use 127.0.0.1, not localhost,
  on this PC. Initial model load took 44.52s; warm before starting the round.
- Real-model typed three-region engine fixture passes interpretation, actual delayed
  report and physical movement. That run's interpretation took 2.282s under engine load.
  Scoped audit passes 33 contexts, 28 changed decisions, 157 deliveries, one model record.
- 552 default/cross-lane assertions; 139 live-perception; 31 new functional scenario;
  seven Python tests. Person 3 structural scenario validation passes with expected unknowns.
- Earlier rendered scenario run: 28 functional checks + PNG save; captured layout inspected.
  The final 31-check functional suite additionally covers guarded elimination/HUD/reset.
- Existing FPS and TCP checkpoints: 41 and 22 checks respectively. Do not sum historical
  runs into a fresh claim. Known navigation-bake GPU readback warning remains.

No confirmed human voice-to-Lotus test, exported-build acceptance, OS-network-disabled
test, backup video, full-game/model fairness or training-benefit result exists. The
scenario fixture fast-forwards its authoring clock for +23s checks; normal gameplay
waits real time. A guarded test health pool is fixture-only and resets to normal values.

## Next work, in order

1. Inspect current code/status and any new Person 3 updates without overwriting work.
   Validate the current spoken voice-to-Lotus path on the actual PC and record results.
   Do not redo the completed model download/standalone five-call test unless needed.
2. Coordinate the paired belief/planner schema removal and full player-report acceptance;
   test both consumers. Preserve valid uncertainty and actual delivery clocks.
3. Implement the remaining ally/utility baseline from notes with physical feasibility
   and observation guards. Keep player movement human-controlled and kills unforced.
   Preserve the user-selected first-known spawn rule and original map.
4. Close real acceptance gaps: fairness/safety coverage, offline/export test, backup
   video and demo rehearsal. Do not prioritize deferred grading/debrief/evaluation.

Maintain one current handoff and honest component guides. Push reviewable work on the
current branch; do not merge main or edit Person 3 code unilaterally. Source metadata,
pro fidelity, model licensing and measured results must remain explicitly qualified.
