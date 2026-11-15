# Physical motion adapter

[motion_controller.gd](motion_controller.gd) is a privileged own-actor adapter,
separate from the pure planner and command executor. The trusted scene supplies
the actor, navigation provider and copied authored markers/routes. Never pass this
object, actor handles, navigation callbacks or live targets into policies/models.

## Tick order

The runtime samples sensing, advances the executor with previous physical feedback,
applies delivered reports, selects an action/position/plan, then calls motion.step.
Motion validates the complete intent batch and evidence before physical effects.
Executor errors freeze execution; a planner error freezes autonomy. A current
validated action controls motion over autonomous plans.

`stage` follows an authored staging marker; `start_swing` follows the authored
entry route. `throw_flash` delegates to the attached flash adapter and reports
actual launch success/failure. `stop` terminates the corresponding pending task.
Routes cannot survive missing/superseded command IDs. A completed action queues
feedback for a later executor tick rather than self-certifying on dispatch.

Autonomous and persistent-player decisions name an authored target/watch pair.
Holding stops translation and faces its static watch point while the combat
adapter may engage using delayed aim evidence. Watching a region does not mean
the whole region was seen. Target positions are static affordances, not enemy
positions. Reachability, path endpoints and actual movement are checked physically.

## Flash and combat attachments

The visible flash controller turns toward static zone aim points, checks world
and active-smoke LOS/range, and throws in place when feasible. Otherwise motion
walks to seek a reachable throwing view and rechecks continuously. Inventory is
spent only at release; cancellation before release preserves it. An on-cue throw
still waits after staging.

Combat uses copied delayed sensory aim/loss and own blind/smoke state through the
combat controller. Shared weapon physics resolves the shot without returning
hidden target/collider state to policy. Motion does not acquire a truth-based
opponent tracking loop.

## Authored box traversal

The default site has two bidirectional links over existing box_3 to Upper. Motion
calls the shared actor's request_jump with unchanged jump strength/gravity,
centers the landing and waits for actual ground contact before continuing. Downward
links are controlled drops. Failed landing/progress/timeouts stop honestly; no
teleport or extra ramp is provided. This is authored traversal, not general parkour.

Completed player movement is retained by the runtime as a position. To descend
after asking for Upper, the player must issue a new position/action or cancel;
completion alone no longer resumes spike defense. See [scenario](../docs/SCENARIO.md)
and [testing](../docs/TESTING.md).
