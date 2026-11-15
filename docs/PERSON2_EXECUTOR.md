# Person 2 command runtime

**Module reference, not current project status.** The fake-actor executor described
here is now part of a larger integrated prototype. Use [the current handoff](PERSON2_HANDOFF.md)
for ownership, dependencies, installed paths and acceptance state, and
[the scenario guide](../bots/LOTUS_SCENARIO.md) for the current player entry point.
Historical module test results below retain their original scope.

Implemented on person-2/bot-perception. Tested with the official Godot 4.4.1 stable build proposed by Person 1. This is a headless command runtime with fake actor integration, not a playable sandbox, speech interpreter, raycast sensor or professional-play policy.

## Components

- [Observation inbox](../perception/observation_inbox.gd): per-bot delayed delivery, deterministic ordering, copied values, duplicate-ID handling and historical evidence checks. Actual delivery time is recorded so late inputs cannot backdate evidence.
- [Plain-data boundary](../perception/plain_data.gd): excludes live Objects, nonfinite numbers, deep/cyclic containers and excessive individual container sizes.
- [Command executor](../bots/command_executor.gd): reports, swing/flash requests, follow-player or cue timing, rejection, cancellation, supersession, expiry and execution timeout.
- [Validator](../validation/comms_validator.gd): checks the subset used by the bundled comms.v1 schema. This is not a general-purpose JSON Schema library; unsupported validation keywords fail closed.
- [Fake actor](../tests/person2/fake_actor.gd): stages, simulates one swing and decrements flash inventory. It deliberately has no navigation, projectiles or world access.
- [Tests](../tests/person2/run_tests.gd) and [demo](../tests/person2/demo.gd): run in an isolated temporary Godot project. Person 1's root project settings are not created or modified.

## Run

Install Godot **4.4.1 stable**, standard GDScript build, and Python 3.10+. No Python packages or Godot plugins are required.

~~~sh
python validation/run_person2_tests.py --godot "/path/to/godot"
python validation/run_person2_tests.py --godot "/path/to/godot" --demo
~~~

On Windows, pass the full path to Godot_v4.4.1-stable_win64_console.exe. The runner verifies the engine version, creates a disposable project, enforces a timeout, checks the engine exit status/error output and requires the test success marker. Scripts parse/run directly; no editor import or visual project is needed.

GitHub Actions runs the same suite and demo on Linux. Windows sandbox environments may need permission to run Godot outside the sandbox to read the OS certificate store.

## Connect Person 1 and Person 3

The example below is integration pseudocode. The executor itself is real; the production actor/belief adapters below remain each lane's responsibility.

~~~gdscript
const Executor = preload("res://bots/command_executor.gd")
var executor = Executor.new(
    "ally_1",
    {"entries": ["entry_a"], "flashes": ["flash_exit_a"],
     "regions": ["logs"], "speakers": ["player"]},
    schema_dictionary
)

# Every physics tick, exactly once, with monotonically increasing integer ticks:
var output = executor.step(tick, actor_adapter.snapshot(), actor_adapter.take_feedback())
if not output.errors.is_empty():
	# Log it and freeze this bot's physical controller; do not dispatch.
	push_error(str(output.errors))
else:
	actor_adapter.apply(output.intents)
	# Forward reports once to Person 3's belief layer.
# Forward output.results to the recorder/UI, respecting silent-mode speech rules.
~~~

Instantiate a fresh executor per bot per round. Catalog and schema are trusted, static, JSON-compatible configuration loaded by bootstrap code, never model-generated world access. Reset by creating a new executor so pending requests, ID caches and private evidence do not carry across rounds.

### Incoming delayed observations

Call enqueue(observation) from a trusted perception/comms adapter. Check its ok/reason result. Each observation must have exactly these fields:

~~~json
{
  "id": "observation_17",
  "bot_id": "ally_1",
  "event_tick": 100,
  "available_tick": 118,
  "source": "told",
  "speaker_id": "player",
  "content": {
    "type": "comms",
    "message": {}
  }
}
~~~

Replace the empty message with a full [comms.v1 message](COMMANDS.md). The trusted transport stamps event/availability ticks and preserves the speaker identity. A message cannot claim an issue time after the observation event. JSON numeric integers from Godot's JSON parser are accepted.

Motion observations have content {type: "player_entry", actor_id: "player", entry_id: "entry_a"} and source seen/heard. They must come from actual permitted nearby teammate perception, not a global player transform. They only release a follow_player swing if the speaker and entry match and the event occurred at/after readiness. Old movement and cues are not latched.

Equal delivery times are ordered by event tick and then observation ID. The executor expires/ends dead actors first, consumes physical feedback next, then handles due observations. Plan this ordering into the game loop; an input enqueued after a step is consumed no earlier than the next step.

### Person 1: actor adapter

snapshot() returns exactly {alive: bool, flash_count: nonnegative integer, reachable_target_ids: array of strings}. These are own-state plus reachability of static authored targets. Do not include enemy nodes, positions or a world dictionary.

apply(intents) handles these operations in order:

| op | Required physical behavior |
|---|---|
| stage | Navigate to/align with the target's authored staging marker; report staged only when reached |
| start_swing | Follow the authored entry peek route; report completed only after finishing |
| throw_flash | Atomically consume inventory and launch using the shared utility rules |
| stop | Stop the previous command's pending movement/aim task; do not undo a released projectile |

Each intent includes command_id, bot_id, tick, target_id and evidence_ids. Entry and flash marker IDs may differ; register both in their own catalog groups. Ignore stale feedback from superseded tasks.

take_feedback() returns and clears a list of {command_id, phase}, with at most one entry per command per step. phase is staged, completed or failed. Conflicting/batched phases for one command are rejected atomically. It reports only execution of that bot's physical task. Completion requires an executing action dispatched on an earlier tick. Do not report complete simply because an intent was issued.

Flash dispatch is the commit boundary: after throw_flash is emitted, the executor rejects cancellation/replacement until completion/failure. The physical adapter must consume inventory once per command ID and must report failure instead of claiming a successful throw if it cannot launch. A missing completion for either a swing or flash times out after the constructor's max_execution_ticks (default 120, tuning placeholder). Physical projectiles continue independently after release.

No teleportation, instant aim or special utility rules are introduced here. Navigation, actual route progress, collisions, flash effect and camera behavior still need the sandbox.

### Person 3: language, beliefs and results

Normalize flexible language into comms.v1, resolve references from allowed context and request clarification before enqueueing an unresolved command. The executor does not transcribe or interpret natural language.

output.reports forwards permitted testimony, including count/hedge/speaker and evidence IDs. Apply it to the existing belief update path once. Report completed means the executor handed off testimony; it does not mean the enemy report was verified or that a belief implementation is supplied here.

output.results contains the contract's lifecycle records. A duplicate message ID replays its cached result without repeating the action or testimony update; a changed payload with the same ID is rejected. ready is emitted only after staged feedback. Do not fabricate readiness from accepted.

A newly feasible command supersedes an interruptible action. Rejected replacements preserve it; reports never supersede it. A cue for an unready/expired command is rejected, and a newly ready bot requires a new cue issued at/after readiness.

## Checks and limits

The tests cover delayed/private evidence, copied data, strict message shapes, target/recipient/resource validation, fake swing and flash execution, go cues, stale feedback/motion, duplicates, supersession, cancellation, expiry, death, failed execution, timeout, and hidden-state perturbation. A restricted dependency scan checks that policy/inbox source does not perform scene-tree/world lookups.

This demonstrates the current modules' enforced input boundary, not a security sandbox for arbitrary GDScript. Future perception and physics adapters require their own tests. The hidden-state perturbation uses a synthetic privileged world that is never passed into policy.

Still required from other lanes: real sensor/communication delay generation, scene actors, navigation, utility mechanics, language interpretation, belief updates and UI/recording. Still later in Person 2's lane: baseline clip scripts, broader reactive combat policy and scenario feasibility validation. No 3D playtest, speech accuracy or full-game fairness claim is made.
