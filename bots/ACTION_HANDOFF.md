# Person 2 action continuation — 2026-11-15

Branch: `person-2/bot-perception`, continuing existing draft PR #4. This is a
separate action record for the concurrent perception/HUD session. Shared
handoffs, runtime, FPS bootstrap, scenario and validation runner were inspected
read-only and were not edited. Merge this record into shared handoffs only after
agreement through the user. No main merge or replacement scene.

## Implemented increment

Changed `bots/motion_controller.gd`, `tests/person2/motion_tests.gd`,
`tests/person2/run_tests.gd`, and this new record only.

- A bot displaced from a completed autonomous hold/cover/reposition reacquires
  the same authored destination through the existing sole movement controller.
  It queries a fresh path; unreachable navigation stops and latches the existing
  autonomous fault. It does not choose a new tactical destination from truth.
- Staging is physically rechecked while waiting and immediately before a swing
  release. Losing the stage emits `staging_position_lost` physical failure,
  stops movement, and queues failed feedback for the next executor tick. The
  existing comms result remains `failed/execution_failed`; no schema changed.
- A displaced completed swing stops with `completed_route_position_lost` rather
  than replaying the route or emitting completion twice.
- Arrival requires horizontal distance within the existing configured tolerance
  (default 0.25 m), plus vertical difference at most 0.75 m. The latter matches
  the existing path-endpoint tolerance and is a conservative synthetic floor
  approximation, not a validated multi-floor movement design. Small floor
  settling inside these bounds remains a hold and never trips a stuck timer.
- Added nine regressions for the already-correct player-entry discriminator and
  actual delayed release with cited evidence. The executor's outer dispatcher
  already enforced `type=player_entry`; no executor behavior was changed.

Twenty new motion assertions include real executor -> motion -> next-tick
feedback flow using synthetic normalized comms. A cue can be accepted and enter
executing before the physical adapter detects displacement; the next executor
tick records failure. It never records physical completion or moves the route.
Existing cancellation, expiry, death, resource, duplicate-dispatch, stuck and
fault-recovery tests remain in place. Reset still recreates lane objects.

## Existing seam verified by source inspection

- `policy_context_ready`: copied promoted observations, local belief, own state,
  active command; 30-tick cadence and 120-tick context expiry.
- `submit_intent`: pure gate accepts hold/cover/reposition/stop with authored
  markers and context-available evidence; invalid output clears model control.
- `submit_comm`: normalized comms.v1 enters the delayed inbox (18-tick fixture
  delay). Accepted player commands take priority over model/fallback goals.
- `observation_delivered`: deep copy after promotion, with actual delivery tick.
- `comm_result`: copied lifecycle results; `decision_recorded`: copied plan,
  policy source, physical status, model record and errors.

This increment changes none of those interfaces, model goals, beliefs, player
comm acceptance, sensory payloads or shared mechanics. It reads only own actor
pose and static authored destinations inside the existing privileged adapter.

## Actual validation

Official installed engine: `4.4.1.stable.official.49a5bc7b6`.

```powershell
$pythonExe = 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$godotExe = 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
& $pythonExe validation/run_person2_tests.py --godot $godotExe
& $pythonExe validation/run_person2_tests.py --godot $godotExe --person1-ref 487ad73 --person3-ref 57f809d --first-person-smoke
& $pythonExe tools/check_repo.py
git diff --check
```

- Default runner: command assertions report `PERSON2_TESTS_PASS checks=183`,
  then strict runner exits 1 on `ERROR: Failed to read the root certificate store`.
  Remaining default suites are not reached by that invocation.
- Focused motion invocation: copied the existing runner's `FILES` unchanged to
  a disposable project, ran `res://tests/person2/motion_tests.gd` with the same
  engine. It reports `PERSON2_MOTION_PASS checks=77`, then the same certificate
  error. Strict focused check exits 1. Assertion success is not a clean engine
  or full-suite pass. The earlier focused command invocation reported 181
  assertions followed by the certificate error; the final default invocation
  includes two additional coordination regressions (183 total).
- FPS runner resolves read-only Person 1 `487ad73` / Person 3 `57f809d`, then
  exits 1 during temporary editor import on the certificate error. FPS assertions
  are not reached. No error filtering or runner/sensor patch was applied.
- Documentation checker and whitespace check pass. No human playtest,
  microphone/STT/local-model run, export check or new CI pass is claimed.

Rerun the two existing runner commands in an environment where Godot can read
the Windows certificate store. This session cannot request sandbox escalation.
GitHub PR inspection also failed on sandbox network access; remote PR draft
status was not freshly verified or changed.

Publication: action implementation committed locally as `3c6085d`. Attempted
`git push origin person-2/bot-perception`; it failed connecting to GitHub port
443. The later coordination agreement/test additions are a separate local
follow-up. Only this session's explicit paths were committed; concurrent
perception/HUD edits remain untouched.

## Coordination dependencies

The perception session agreed through the user to produce delayed **seen**
observations with exactly
`{type: "player_entry", actor_id: "player", entry_id: "entry"}` from
actual player movement into the entry, requiring fair FOV, LOS, smoke and blind
checks. It owns sensor/runtime wiring. The legacy executor contract also permits
identified `heard` entry observations, but the current producer will not generate
them: anonymous footsteps carry no player identity, especially through walls.
New tests retain that boundary and reject a different entry. Event time must be
at/after readiness; actual delivery controls release. Until wiring is tested,
only synthetic entry/cue fixtures establish this behavior. No global player
transform enters policy.

Combat remains blocked on agreement for a separate delayed last-observed aim
payload: observation ID, bot ID, event/availability ticks, opponent ID, copied
last-observed aim point in meters/Y-up, and permitted observation source. Agree
freshness/cutoff and own blind/smoke fire restrictions with the perception owner;
never add coordinates to the existing `enemy_seen` belief payload silently.
Use shared Weapon fire/reload once that seam is agreed; no live target handle.

Defuse needs an agreed own/public objective input (known planted objective ID,
authored reachable marker, public round-active/resolved state), goal/lifecycle
support and exclusive defuser arbitration. Person 1's `scenes/main.gd` currently
calls shared `Spike.stop_defuse()` whenever the player is not defusing, so a
second independent bot caller could have its progress reset every frame. Resolve
that shared ownership through Person 1 before enabling physical bot defuse;
do not change the shared main/mechanics from this lane. Completion must come
from actual shared defuse success, not goal submission or travel time.

The other session retains smoke reacquisition, actual traveling blind-wave
effects, delivery and HUD work. Person 3 retains voice/LLM/working-belief
full-acceptance corrections and exact prompt/output logging. Verified pro notes
remain required for source-derived scenarios. New broader actions and changes
to runtime/scene/scenario/runner/shared handoffs require exact coordination.
