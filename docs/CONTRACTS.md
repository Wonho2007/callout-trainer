# Current integration contracts

The selected player message schema is [comms.v1](COMMANDS.md) and
[its JSON Schema](../schemas/comms_v1.schema.json). Current implementation details live
in the [voice/game guide](../bots/VOICE_GAME.md), [scenario guide](../bots/LOTUS_SCENARIO.md)
and [executor reference](PERSON2_EXECUTOR.md). Old proposed v0 examples remain historical
fixtures; they are not automatically upgraded APIs.

## Boundaries in use

| Boundary | Actual shape / responsibility |
|---|---|
| Interpreter -> Godot | Proposal only. Model cannot assign trusted message IDs/ticks, world coordinates or direct actor operations |
| Godot -> delayed inbox | Trusted host stamps current receipt tick + 1, speaker/recipient/expiry and observation ID; existing 18-tick fixture delay applies |
| Observation | `{id, bot_id, event_tick, available_tick, source, speaker_id, content}`; copied plain data. Actual delivery tick is logged separately |
| Belief -> planner | Pinned `57f809d`: `{bot_id, tick, enemies, trust, evidence_ids}`. `trust: {}` is inert compatibility data, not a credibility feature |
| Model context | `{context_id, bot_id, tick, expires_tick, observations, belief, own_state, active_command}`; released bot-local observations only |
| Optional model candidate | `{context_id, decision_id, bot_id, goal, target_id, watch_region_id, evidence_ids}`; gate validates copied recorded context, allowed markers, evidence and expiry |
| Physical executor | Receives authored target IDs, permitted delayed last-observed aim and own-state; shared physics resolves paths, shots and utility without returning hidden targets to policy |
| Local bridge | Localhost-only JSON-lines transport with round session, request deduplication, bounded buffers and heartbeat/disconnect fallback. Internal integration seam, not a new shared schema version |
| Late enemy registration | Privileged scene adds real actor to sensing registry only. No spawn testimony, guessed initial body or reset of legitimate pending observations |
| Source scenario | Uses Person 3 scenario.v1 schema/validator read-only from its snapshot; own checks bind unknown starts and first-known beats to runtime schedule/region bounds |

The approved paired field-removal work is on Person 3's `comms-belief` and
`drop-trust-planner` branches. Changing only one consumer breaks validation. Field
removal alone does not fix the known working-belief full-acceptance behavior.

## Time and evidence

The authored scenario clock starts at plant and uses 60Hz ticks; arrivals are at tick
1380. Runtime clocks are monotonic per bot; late-created enemies start their own runtime
clock when instantiated. Do not compare different clock domains without conversion.
Model/STT wall-time is telemetry, not permission to backdate game evidence.

Every cited observation must belong to that bot and have actually been delivered by
the decision/context tick. Keep event, configured availability and actual delivery
distinct. Reject foreign/future/expired evidence. A reset creates a new session; old
speech/model replies cannot operate the new actor. Physical completion is measured,
not inferred from emitting an intent.

Static map/marker affordances may be public. Model/policy cannot receive live enemy
Nodes/transforms, scene-tree lookup access, private truth streams or player-only recon.
Delayed `enemy_aim` is a copied actually visible torso sample, not live target tracking.
Public terminal round outcomes may stop the controller; private truth cannot choose
a tactical branch. Fallback obeys the same information boundary.

For nondeterministic model attempts, preserve exact inputs, schema/options, prompt,
raw output, parsed result, error/source and context ID. Do not substitute deterministic
replay for auditing what the model actually received. The documentation checker verifies
links/fixtures only; passing it is not a fairness gate.
