# Natural-language communication contract v1

Status: selected by the user for implementation on Person 2's branch. This defines the boundary for Persons 1/2/3; it does not claim a parser, speech service or bot executor is implemented. Other engine-wide contracts remain proposed. Coordinate changes through a PR; do not silently change these names.

## Responsibility and scope

- Person 3: speech/transcript input, paraphrase interpretation, contextual references, clarification, belief/report handling, UI acknowledgments and logs.
- Person 2 (Wonho2007): validate commands against permitted bot inputs; execute/interrupt authored behavior; publish lifecycle results and decision evidence.
- Person 1: shared movement/flash mechanics and authored entry/flash markers. Expose nearby teammate movement only through the agreed perception interface.

The user wants flexible language, not exact keyword-only phrases. Use a natural-language interpreter to normalize paraphrases into this contract; a small language model is an option, provider/model remains open. Keep deterministic structured/menu and alias fallbacks. First build against typed transcripts. Voice is the desired input; quick-call remains the mandatory demo fallback. Never require a paid API.

Initial actions: swing_together, throw_flash, report_enemy. Supporting cue/cancel messages manage timing and interruption. Unsupported tactical actions get an honest response, not invented behavior. Repeated messages throughout the round are supported.

## Message envelope

See [the JSON Schema](../schemas/comms_v1.schema.json) and [synthetic examples](../examples/comms_v1.json).

All fields required: schema_version ("comms.v1"), message_id, speaker_id, recipient_id, issued_tick, expires_tick, kind, payload. Each message addresses one allied bot; Person 3 expands an explicit team broadcast into separate addressed messages. No hidden-state-based recipient selection.

A trusted adapter assigns IDs, actor IDs and simulation ticks; the language model only proposes intent/targets/timing. Reject unknown fields, malformed output and unsupported IDs. Require expires_tick > issued_tick. Expiry is scenario-configured, never invented by a model. Example ticks/IDs are illustrative, not real map data or fixed tuning.

| kind | payload | Meaning |
|---|---|---|
| command | action: swing_together; target_id: entry marker; timing.mode | Coordinate the authored entry/peek route |
| command | action: throw_flash; target_id: flash marker; timing.mode | Throw using shared flash mechanics |
| report | action: report_enemy; region_id; count; hedge | Update belief, never set confirmed truth |
| cue | command_id | Release an already-ready on_cue command |
| cancel | command_id | Cancel that speaker's active interruptible command |

A report count is a positive integer or null for unspecified; never infer "one" merely from "someone." Hedge is sure/think/unsure. Existing report fixtures remain legacy illustrative v0; adapt new reports into the same belief update path. Parser certainty and speaker reliability are separate concepts.

## Natural language and context

"Swing with me" and "let's peek together" normalize to swing_together/follow_player at the same known entry. "Double swing" means coordinated peeking here, not an instruction to jump or fire twice. "Flash through that smoke" and "flash out the smoke" resolve to the relevant authored flash marker, not arbitrary model-generated coordinates.

Resolve references using recent conversation, static marker IDs and bot-permitted observations only. "That smoke" needs a unique known smoke/associated marker; "with me" needs a unique known entry. Otherwise ask "Which entrance?" or "Flash which smoke?" Do not emit an executable message until resolved. Preserve separate intents in compound speech; issue a clarification if action order/timing is ambiguous.

Enemy reports go to Person 3's belief layer via delayed told observations. Person 2 reads resulting local beliefs and may choose coverage; the report is not a forced movement command. Commands also arrive through a delayed observation and cite that evidence.

## Timing, countdowns and late input

- follow_player: move to the authored staging position; emit ready; start the route when delayed permitted perception detects the nearby player's entry movement. Use observed player motion, never a global player transform.
- now: start as soon as the request is available, validated and feasible. It never bypasses reaction delay.
- on_cue: stage and emit ready, then wait for a cue referencing this command. The bot only acts after that cue becomes available.
- throw_flash accepts now/on_cue; swing_together accepts all three modes.

A countdown and "swing with me" share an action, but not necessarily timing. For reliable countdown coordination, first prepare the swing ("on my count"), wait for ready, then deliver the final go cue through a fast deterministic speech/structured cue path. Keep expensive language-model interpretation outside the final release path.

Do not assume a completed push-to-talk transcript can synchronize a countdown that already ended. If no command is armed, a countdown requires a newly validated swing and cannot execute retroactively. If the bot is unready when a cue arrives, reject the cue with not_ready; retain preparation until expiry or cancellation and require another cue after ready. Expired/late cues cannot unexpectedly launch a pending swing.

## Lifecycle and multiple requests

Person 2 emits result objects with schema_version, result_id, message_id, bot_id, tick, status, reason_code and evidence_ids. They contain copied values only. Valid statuses: accepted, ready, executing, completed, rejected, failed, cancelled, expired.

- accepted means validated and scheduled; ready means staged and waiting; executing means physical action started; completed means it finished.
- rejected means validation failed; failed means accepted execution became impossible. Both include a reason.
- cancelled/expired terminate an accepted pending action. Commands are single-active per bot in v1; no hidden queue.
- A newly validated, feasible command replaces an interruptible active command and emits cancelled/superseded for the old one. Rejecting a new request leaves the old action unchanged.
- Committed throws cannot be undone. Reject a conflicting request with busy_committed rather than claiming cancellation.
- Reports update beliefs without replacing an action. Completing a report means processing it, not verifying its truth.
- Re-delivery of the same message_id returns the last result, without repeating a flash or applying testimony twice. Distinct IDs are new requests, validated again.
- Cue/cancel references must belong to the same speaker, recipient and active command. Wrong/unknown references are rejected.

Suggested reason_code values: ok, invalid_message, unknown_target, ambiguous_target, no_utility, unreachable, actor_dead, busy_committed, not_ready, expired, unknown_command, superseded, cancelled_by_player, execution_failed. Fixed parser/model confidence thresholds are not part of this contract.

Person 3 renders short contextual acknowledgments, such as "Getting ready", "Ready", "Flashing", "No flash left". Do not say "Ready" before the executor reports ready. In the silent comparison arm, record lifecycle results and display essential status without bot speech; use the same execution rules in every arm.

## Validation and fairness

Before acceptance: validate schema and known IDs, ally recipient, time window, actor alive, required utility, reachable authored route/target and action state. No target IDs or model explanation grant access to hidden enemies. All results/decisions cite observations available to that bot at that tick. Commands can interrupt the baseline plan; resume it only if its guards still hold.

Log transcript, normalized message, parser outcome and timestamps separately from the bot-local evidence stream. Only permitted structured observations enter policy. Log clarification and failures as well as success. A rejected/unclear parse never causes an action.

## First integration checks

- Paraphrases produce the same action and target; timing differences are preserved.
- A logs report changes beliefs without cancelling an active swing.
- A repeated message ID cannot throw two flashes.
- No flash remaining produces rejected/no_utility.
- An unready or expired go cue cannot launch a swing.
- Ambiguous smoke/entry produces clarification, not guessed coordinates.
- Unseen enemy movement cannot change these decisions when all permitted inputs match.

The schema and examples are interface artifacts. These behavioral checks still need implementation with the observation/leak fixture; no speech accuracy, model performance or gameplay pass is claimed.
