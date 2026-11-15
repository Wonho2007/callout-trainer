# Physical movement slice

[motion_controller.gd](motion_controller.gd) is a **privileged physical adapter**, separate from the pure knowledge planner and command executor. Its handles stay on the scene/bootstrap side. Never put the controller, actor, navigation object, callbacks or live targets in policy inputs.

The adapter follows authored coverage markers, stages and follows authored swing routes through Person 1's existing actor/navigation methods, and turns the actor toward a static watch point. It does not aim at an opponent, fire, grant visibility, clear regions or model a combat aim/reaction curve. A watched region is an authored angle, not evidence that its whole volume is visible. Turning is immediate placeholder movement presentation, not the eventual combat aim model.

Current FPS extension: trusted bootstrap may call `attach_flash(adapter)` with the privileged [flash controller](flash_controller.gd). Flash stage intents use its authored stage marker through this same movement dispatcher; release intents halt movement and atomically launch through shared utility. Physical success queues completed feedback for the next executor tick; failure queues failed feedback and preserves the detailed reason in physical telemetry. Without the attachment, flash still fails honestly. No planner/executor dependency on live mechanics is introduced. See [FPS command semantics and tests](FIRST_PERSON.md).

## Inputs and ordering

Create one instance per bot per round, from trusted bootstrap code:

~~~gdscript
const Motion = preload("res://bots/motion_controller.gd")
var motion = Motion.new(bot_id, own_actor, sandbox_builder,
    authored_motion_markers, authored_entries)
~~~

Only `own_actor` and the static navigation provider are registered. This adapter never takes an opponent registry or looks up scene nodes. Current tested APIs are Person 1's `set_move_dir(Vector3)`, `move_toward_point(Vector3) -> float`, `is_alive`, `navigation_is_ready` and `query_path(from, to) -> PackedVector3Array`. It reads/moves only its own actor and resolves static destinations into navigation paths.

Motion configuration is JSON-compatible copied data, separate from planner configuration:

~~~json
{
  "markers": {
    "home": {"position": [-5, 0, 7], "watch_points": {"region_a": [-6, 0, -6]}},
    "cover": {"position": [5, 0, 7], "watch_points": {"region_b": [6, 0, 6]}}
  },
  "entries": {
    "entry": {"stage_marker_id": "home", "route_marker_ids": ["cover"]}
  }
}
~~~

Pass `markers` and `entries` as the constructor's separate dictionaries. These coordinates/IDs are synthetic test data, not final shared map/command markers. Shared consumers must agree on IDs before live wiring. Positions use meters/Y up. Markers must be walkable, and each planner marker/watch-region combination needs its matching static watch point. The path endpoint snap tolerance is 0.75 m (including vertical offset); arrival is horizontal within 0.25 m by default. These are conservative placeholders for this floor-level slice; slopes/elevation and human movement feel remain unverified.

Once each physics tick, before the actor's physical movement callback:

~~~gdscript
var output = executor.step(tick, physical_snapshot, motion.take_feedback())
# Apply accepted reports to Person 3 exactly once, retaining observation IDs.
var plan = planner.decide(tick, belief.snapshot(), planner_own_state,
    executor.inbox, executor.active_command_snapshot())
var physical_status = motion.step(tick, plan, output,
    executor.active_command_snapshot(), executor.inbox)
# Record plan, executor lifecycle and physical_status separately.
~~~

This controller owns dispatch for these movement intents. Do not additionally forward the same intents to another actor driver. `goal=command` never dispatches an action; only executor intents do. Use the trusted executor's active snapshot, not a fabricated command. `take_feedback()` drains physical feedback for the **next** executor step. Actual arrival produces `staged`/`completed`; submitting an intent never establishes completion. Stage/start/stop operations are deduplicated per command ID for the round.

An accepted command suspends autonomy even if the planner's belief input fails. A planner error stops routine movement. An executor error stops all movement. Death, invalid plans/evidence and non-monotonic ticks stop safely. Cancel/expiry/supersession stop abandoned routes; routine motion resumes from a new plan. A terminal stop blocks autonomous movement for that tick. A same-batch cancel wins over an earlier start intent.

`throw_flash` deliberately returns `failed` feedback with physical reason `utility_adapter_unavailable`. This slice must be configured without feasible flash targets/inventory until the shared launch/consumption adapter is implemented; it cannot consume inventory or claim a throw. Unsupported flash staging also fails rather than guessing a movement target. The executor's general flash logic remains tested by the older fake-actor suite only.

## Physical failure and recovery

Empty/nonfinite paths, snapped/partial endpoints, unsynchronized navigation or lack of improved distance to the next path point cause a conservative stop with a reason. Stuck defaults to 120 ticks with at least 0.1 m improvement; oscillation without improved distance cannot keep resetting it. A legitimate stationary hold never enters the stuck timer. A physical command failure returns `failed` feedback to the executor. Autonomous physical failures latch until trusted integration inspects and recovers the state and calls `reset_fault()`; an accepted player command can still take priority. Recreate all lane objects on round restart.

Return values are plain `{ok, state, reason, tick, bot_id}`. `ok=true, state=failed` is an observed physical failure; `ok=false` is an invalid integration input. Record/display these reasons through Person 3's UI; this slice has no visible circuit-breaker banner. It is not the full OOD/action-entropy/fallback system. Dynamic re-pathing, avoidance between actors, combat and source-derived scenarios remain future work.

## Reproduce automated checks

~~~powershell
python validation/run_person2_tests.py --godot <Godot4.4.1_console>
python validation/run_person2_tests.py --godot <Godot4.4.1_console> --person1-ref 0fd1285 --person3-ref ff2a6d7
~~~

Default tests use explicit motion actor/navigation doubles for failure and arbitration assertions. The optional integration reads four Person 1 files and three Person 3 files with `git show`, without checking out or editing either branch. It generates a disposable Godot project, registers existing shared classes, bakes Person 1's actual synthetic room, moves its actual `CharacterBody3D` with collision/health, and applies accepted reports to Person 3's actual belief module. Existing `--person3-root` remains supported and is mutually exclusive with `--person3-ref`. Optional shared integrations are local checks, not part of current CI.

**Person 1 dependency discovered:** at `0fd1285`, the builder's navmesh uses cell size/height 0.2/0.1 while its project has default map cells 0.25/0.25. The first integration run produced engine errors and was correctly rejected despite assertion pass markers. The fixture explicitly matches **only its temporary navigation map** before the bake and allows the signal-emitting physics frame to finish before querying. No production setting or teammate source was fixed here. Person 1 must align production map/mesh settings and confirm readiness. Its runtime bake also emits a GPU mesh-readback performance warning; report that warning separately from failure.

The fixture tests a delayed report causing physical coverage movement and watched angle, one command override/physical completion, cancellation, expiry, shared health death, available evidence and an actual unseen scene-node perturbation. Existing planner tests separately cover stale testimony. These checks do not establish complete scene fairness, quick-call UI input, real utility, source-derived tactics or training benefit.

## Manual gate (not performed)

No rendered/shared-game playtest has been performed. A standalone overhead demo is now available without editing the root project or opening the editor:

~~~powershell
Set-Location C:\Users\Isoto\Documents\GitHub\callout-trainer
& 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe' validation/run_person2_tests.py --godot 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe' --visual-demo
~~~

The runner builds a temporary project from the owned demo scene and read-only teammate refs `0fd1285`/`ff2a6d7`, imports it headlessly, then opens a normal Godot game window. Close the window or press Esc to return to the terminal and clean up the temporary project. Godot 4.4.1 is required; use your own executable paths on other machines. These refs must exist locally (fetch first if needed). Override `--person1-ref`/`--person3-ref` to inspect newer compatible revisions. This branch has no shared root main scene to launch with F6/F5 for this demo; the preparation command supplies all dependencies.

Blue is the teammate; yellow shows its forward direction; green is home/staging; pink is the authored coverage destination. This is synthetic movement presentation with injected structured reports, not Person 3's quick-call UI, live speech, physical perception or the first-person game. Buttons have matching shortcuts:

1. Press **1**: after 18 ticks (0.3 s at the default 60 Hz), the teammate should walk from green to pink and turn toward B. The displayed evidence should include the report ID. Freshness expires after 600 ticks (10 s), so it eventually returns home; report again to refresh.
2. While moving, press **2**: the accepted command takes priority, returns to green to stage, then performs one route to pink. Watch accepted -> ready -> executing -> completed in the status line as they occur.
3. Press **3**: the teammate stages at green, shows ready, and waits. Press **4** only after ready to release it. An early cue should report not_ready. Waiting without a cue eventually expires the command.
4. During staging/movement press **X**: after delivery delay, the command is cancelled and its route stops. Routine coverage can resume on the following tick; cancellation is not a permanent freeze.
5. Press **K**: the actor should stop as dead. Press **R**: revive at home, clear evidence/pending commands, and restart the exercise.

Record tester, build/scene, keys/buttons, observed movement/angle, unexpected clipping/stuck behavior and error messages. The runner's `--visual-smoke` option performs an automated **headless** lifecycle check of these same action callbacks, including physical movement and reset. It does not validate rendering, mouse/keyboard input, on-screen layout or human experience.

The shared-game manual gate still requires Person 1's coordinated bootstrap/nav settings, actual player/quick-call delivery, sightlines and utility wiring. No standalone demo pass substitutes for those integration checks.
