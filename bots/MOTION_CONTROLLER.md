# Physical movement slice

[motion_controller.gd](motion_controller.gd) is a **privileged physical adapter**, separate from the pure knowledge planner and command executor. Its handles stay on the scene/bootstrap side. Never put the controller, actor, navigation object, callbacks or live targets in policy inputs.

The adapter follows authored coverage markers, stages and follows authored swing routes through Person 1's existing actor/navigation methods, and turns the actor toward a static watch point. It does not aim at an opponent, fire, grant visibility, clear regions or model a combat aim/reaction curve. A watched region is an authored angle, not evidence that its whole volume is visible. Turning is immediate placeholder movement presentation, not the eventual combat aim model.

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

No rendered/shared-game playtest has been performed. After Person 1 coordinates the shared bootstrap and nav settings, a human must launch the synthetic room using that lane's launch instructions, report a threat hidden from the teammate, observe delayed movement and the final angle, issue/cancel/expire a swing while it is moving, and kill/reset the actor. Check collision/stuck behavior, visible failure reasons and restart. Record tester, build/scene, steps and observed results; no headless pass substitutes for this gate.
