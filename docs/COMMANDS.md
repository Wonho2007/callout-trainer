# Communication contract

The demo interprets natural speech locally, then validates a normalized proposal
against `comms.v1`. See [the JSON Schema](../schemas/comms_v1.schema.json),
[examples](../examples/comms_v1.json) and [architecture](ARCHITECTURE.md).
The model supplies intent/targets/timing; the trusted bridge supplies IDs, recipient,
receipt tick and expiry. It maps public region names to authored action targets.

## Shared envelope

All messages contain `schema_version`, `message_id`, `speaker_id`, `recipient_id`,
`issued_tick`, `expires_tick`, `kind`, and `payload`. A message addresses one bot.
Unknown fields/IDs, malformed payloads, future issue times and expired commands
are rejected. Expiry must be later than issue time. Stable request IDs deduplicate
transport retries; the same message ID cannot perform an action twice.

| Kind | Payload | Meaning |
|---|---|---|
| command | `action: swing_together`, `target_id`, `timing.mode` | Stage and traverse an authored entry route |
| command | `action: throw_flash`, `target_id`, `timing.mode` | Stage/seek visibility and release a shared flash |
| report | `action: report_enemy`, `region_id`, `count`, `hedge` | Deliver testimony, not confirmed world truth |
| cue | `command_id` | Release the same speaker's ready on-cue action |
| cancel | `command_id` | Cancel the same speaker's interruptible active action |

`count` is a positive integer or null when unspecified; "someone" need not mean
exactly one. `hedge` is `sure`, `think`, or `unsure`. Preserve what the player
actually said rather than inventing enemy identity, coordinates or confidence.
The pinned belief implementation still has a known mismatch with the intended
full acceptance of player testimony; no credibility/history filter is supported.

## Timing and physical lifecycle

Swing timing supports `now`, `on_cue` and `follow_player`. Flash supports `now` and
`on_cue`. "Get ready to swing" is guarded as on-cue even if the model proposes now.
On-cue staging is physical: the executor reports ready only after stage feedback,
then waits for a separate delivered cue. Early cues do not latch. Follow-player
timing uses permitted delayed teammate-entry evidence after readiness, not a live
player-transform shortcut. Even a now action must satisfy its physical requirements.

The runtime stamps receipt and applies 18 ticks of radio delay. The executor has
one active action per bot. A feasible new action supersedes a cancellable one;
an invalid request leaves it intact. Projectile release is the commit boundary:
a committed throw cannot be refunded or undone. Physical completion/failure
comes back from adapters on a later tick. Expiry, death, cancellation and execution
timeouts terminate pending work according to the executor's rules.

Results contain `schema_version`, `result_id`, `message_id`, `bot_id`, `tick`,
`status`, `reason_code`, and `evidence_ids`. Status is `accepted`, `ready`,
`executing`, `completed`, `rejected`, `failed`, `cancelled`, or `expired`.
Completing a report means processing testimony, not verifying it against truth.

## Local persistent positioning

Explicit region positioning/pushes are a local bridge/runtime extension, not new
actions in the shared schema. The engine grounds a single known zone from an
imperative such as "play Heaven with me" or "let's push A Link together" and
enqueues a `told` observation with content:

```json
{"type":"player_position","target_id":"b_heaven"}
```

The bot accepts it only after ordinary delivery. Its authored position persists
until superseded/cancelled or death/round reset, regardless of the short action
expiry. Completed swing routes likewise retain their reached endpoint, citing
delivered command evidence. Duplicate completions cannot replace a newer goal.
Flash actions can temporarily take control and then resume the position.

A new position uses the existing cancellation rules for pending actions. An
unreachable position stops honestly; it does not silently substitute spike defense.
No goal tracks the player's hidden/live transform. Reports do not overwrite a
position, and ambiguity does not authorize inventing a destination.

## Executor integration

`bots/command_executor.gd` is a pure state machine with a bot-owned delayed inbox,
static catalog and schema. Its own-state input is alive, flash inventory and known
reachable targets. Feedback is `{command_id, phase}` with phase `staged`, `completed`
or `failed`; stale/conflicting feedback cannot complete an unrelated action.

Physical intents are `stage`, `start_swing`, `throw_flash`, and `stop`, with command,
bot, tick, authored target and evidence IDs. Adapters never report success merely
because an intent was emitted. Flash inventory is spent atomically at release.
Create fresh runtime/executor state for a round, and keep scene objects out of
policy inputs. See [motion](../bots/MOTION_CONTROLLER.md) and
[contracts](CONTRACTS.md) for the boundary.
