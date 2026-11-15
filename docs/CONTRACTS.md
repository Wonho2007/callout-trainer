# Integration contracts

The [communication schema](COMMANDS.md) describes reports, actions and lifecycle.
This document records the boundaries used by the hackathon demo rather than old
team ownership or proposed future interfaces.

| Boundary | Shape / rule |
|---|---|
| Interpreter to engine | Intent proposal only; no trusted IDs, ticks, world coordinates or direct actor operations |
| Engine to inbox | Godot stamps receipt tick + 1 and applies ordinary 18-tick radio delivery |
| Observation | `{id, bot_id, event_tick, available_tick, source, speaker_id, content}`; copied plain data, actual release time tracked separately |
| Belief to planner | Pinned `57f809d`: `{bot_id, tick, enemies, trust, evidence_ids}`; inert `trust: {}` remains compatibility data |
| Model context | `{context_id, bot_id, tick, expires_tick, observations, belief, own_state, active_command}`; bot-local delivered observations only |
| Optional model candidate | `{context_id, decision_id, bot_id, goal, target_id, watch_region_id, evidence_ids}`; gated by recorded context, authored affordances, reachability and expiry |
| Player position | Internal delayed `player_position` observation from the local bridge, validated against authored markers; does not change comms.v1 |
| Physical executor | Own actor plus static destinations and permitted delayed aim samples; resolves actual physics without passing hidden target/collider truth into policy |
| Voice bridge | Localhost JSON-lines TCP, per-round session, request deduplication, bounded buffers and heartbeat/disconnect fallback |
| Late registration | Adds actors only to privileged sensing registries; never injects spawn testimony or discards pending evidence |
| Privileged event bus | Records world/gameplay results; separate from policy/model observation inputs |

## Time and evidence

The authored scenario clock starts at plant and uses 60Hz ticks; arrivals are at
tick 1380. Bot runtimes have their own monotonic clocks, including late-created
enemies. Do not compare different clock domains without conversion.

Cited evidence must belong to that bot and have actually been released by the
decision/context tick. Preserve event time, configured availability and actual
delivery time separately. Reject foreign, future or expired evidence. Slow STT
or model inference cannot backdate information. Restart creates new session/runtime
state; old-round replies cannot move new actors.

## World and policy separation

World-space data uses meters, Y up, and JSON vectors `[x, y, z]`. Actor movement,
utility, navigation and sensors may inspect physics as privileged adapters.
Policies receive copied permitted values, never live enemy Nodes/transforms,
scene-tree lookup handles, unrestricted truth streams or player-only minimap/recon.

Static map affordances and public round outcomes are permitted. Delayed
`enemy_aim` contains a copied torso sample that passed actual visibility checks;
`enemy_lost` invalidates it without exposing a hidden cause/location. Combat uses
a maximum aim age of 30 ticks and immediate copied own blind/smoke guards.

The belief snapshot and planner still share a compatibility field; changing one
consumer alone breaks the interface. Removing that field would not by itself fix
the known hedge/full-acceptance mismatch. Coordinate shared schema changes across
both source dependencies and consumers.

## Records and validation

Record exact model inputs/options/prompts/raw outputs and the parsed result for
model runs. Replay or a schema check does not prove what a model actually saw.
Documentation validation checks links and sanitized fixture consistency; broader
fairness requires actual recorded contexts, delivery ownership and causal tests.
See [testing](TESTING.md) for commands and the limits of the recorded results.
