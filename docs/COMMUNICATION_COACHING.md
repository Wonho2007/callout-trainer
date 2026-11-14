# Communication coaching and missed information

**User-directed objective:** clear, useful team communication throughout the round. Readiness coordination is one skill, not the primary or only training objective. The product should identify both unclear messages and relevant information the player could have shared but did not.

This is the coaching specification. The existing Person 2 executor supplies some timing/lifecycle evidence; the full grader, death context and feedback UI are not implemented by this update.

## Skill coverage

| Skill | Situation to recognize | Example coaching |
|---|---|---|
| Timely enemy report | Player has a credible sighting that an actionable teammate lacks | "You saw an enemy at logs, but your teammate had no report before covering the entrance. Call the location while it is still useful." |
| Utility coordination before entry | The selected practice drill needs coordinated utility; a feasible teammate utility option exists and no usable plan/request was established | "You entered without establishing a flash plan. Before this entry, ask for a flash and confirm the timing." |
| Ready/cue coordination | A go cue precedes teammate readiness | "Your swing cue arrived before your teammate reached staging. On the next attempt, wait for ready before starting the countdown." |
| Death report | Player dies and has useful, permitted knowledge of the opponent or last-known threat location that surviving teammates lack | "After dying, report the opponent if known and where the threat was last seen. Your teammate did not receive that location." |
| Corrections and uncertainty | A prior report is stale, contradicted, or was only an estimate | "That was your last sighting, not a current position. Add 'last seen' or 'I think' when appropriate." |

These examples are illustrative, not measured outcomes or verified details of a selected pro clip. Accept natural paraphrases and combinations of messages; do not require a magic sentence or penalize a valid report because it used different words.

Utility use is situational: do not mark every entry without a flash as a mistake. The drill author must explain why the communication opportunity is relevant, verify that utility/timing is feasible, and allow an already communicated or adequately coordinated alternative.

## Detect an opportunity before declaring an omission

An eligible missing-information opportunity needs:

1. **Player knowledge:** the relevant fact was available to the player through a recorded sighting, hearing cue, allowed death-screen information or explicit prior communication.
2. **Recipient gap:** at least one relevant surviving teammate had not independently received equivalent usable information. Check its observation/communication history, not only a probability threshold.
3. **Decision relevance:** the information or request could still inform a scenario-relevant action or coordination choice within a documented window.
4. **Reasonable chance to communicate:** account for when information became available, death transitions and input/channel availability.
5. **No equivalent message already supplied:** match meaning, region, temporal context and valid paraphrases. Do not punish a missing exact keyword.

If those conditions are not established, record "not assessed" or "coaching suggestion" instead of a scored omission. No fixed global timing threshold is implied: windows are scenario-configured, documented and tested.

The privileged grader may inspect truth to assess accuracy, but must not use hidden truth to demand facts the player could not know or send it to live bot policy.

## Death reports

Separate facts the player knows:

- Who killed them, only if identifiable from permitted observation/UI.
- Where the enemy was last observed, with its timestamp.
- Where the player died, which is not automatically the killer's location.
- Unknown identity or uncertain attack direction, which should remain explicitly uncertain.

Never tell the player to name a hidden shooter or invent a precise position from the simulator's killer record. If only a last-known location is available, accept an appropriately hedged report. Do not require the player to continue tracking a moving enemy after death.

The player must be able to speak after their character dies, and surviving bots must continue receiving those reports. Do not disable the input channel merely because the player actor is dead. Respect whatever death-screen knowledge rules are selected for the simulator.

## Distinguish missing speech from system failure

Track stages separately:

player opportunity -> utterance/input attempt -> transcript -> interpreted message -> recipient delivery -> bot observation -> acknowledgment/action.

A report absent from the bot's knowledge does not prove the player failed to communicate. If the transcript already contains the relevant information but interpretation or delivery failed, label a system/interpretation failure and do not score it as a player omission. If audio/transcript evidence is unavailable, say it cannot be distinguished.

A correct request may still fail because the bot has no flash, is not ready, cannot reach staging, or encounters a controller bug. Diagnose those separately from communication clarity. More talking and repeating information the recipient already has are not automatic improvements.

## Feedback record for Person 3

Proposed offline grading record, separate from the executable comms.v1 message schema:

- opportunity_id, skill, trigger_tick, closing_tick;
- player_evidence_ids and recipient bot IDs;
- relevant missing fields (location, target, intent, timing, identity-if-known);
- matched utterance/message IDs or omission/system-failure/not-assessed classification;
- bot evidence/result IDs at the decision point;
- eligibility explanation, observed consequence, concise next-attempt suggestion.

Do not claim a death, loss or changed round outcome was caused by missing speech without a supporting comparison. It is valid to say "the bot did not receive this information"; predicting a saved round requires separate evidence.

## Work split and compatibility

- **Person 1:** emit player-permitted perception/death/UI and entry/utility events; retain speech/menu input after player death; expose actor resource/readiness and shared utility mechanics.
- **Person 2:** expose each bot's delivered observations, readiness/results and decision evidence; accept post-death player reports through living recipients; build actual sensors/planner without granting hidden knowledge.
- **Person 3:** interpret flexible speech, define semantic matches and scenario-specific opportunity windows, grade missing/unclear information, separate parser failures, and present debrief/retry feedback.

Existing comms.v1 can represent an enemy-location report and flash/swing requests. Its strict report payload has no killer identity or explicit "last seen/death" fields. Person 3 may first retain those details as offline parser/grader annotations; a coordinated versioned schema/runtime extension is needed before using those extra fields in live policy. Do not silently add fields that the current executor rejects.

## Evaluation

Clear communication is the umbrella outcome; report skill-level measures rather than early-cue rate alone:

- Accurate/timely reports divided by eligible information-sharing opportunities.
- Relevant omissions, excluding unknown/unobservable facts and system failures.
- Completeness of location, identity-if-known, intention and timing where applicable.
- Utility-plan and readiness coordination, only in eligible drills.
- Appropriate corrections/uncertainty; parser and delivery failures reported separately.

For a small pre/practice/post pilot, use changed situations and disable corrective coaching hints during the post-test while retaining normal teammate acknowledgments. Keep mechanics/interpreter settings consistent and report small-sample limitations. Practice in this simulator alone is not evidence of transfer to human teammates.

## Acceptance examples for later implementation

- Player sees logs enemy; teammate lacks it; no equivalent report before the relevant decision: eligible omission.
- Teammate already saw the same enemy: no missing-information penalty.
- "Someone behind the logs" matches the relevant region/meaning: accept the paraphrase.
- Player says it, but parser drops the location: interpretation failure, not player silence.
- Player dies knowing the last-seen region but not identity: accept that report; do not demand a name.
- Player dies to an unobserved enemy: no exact-location requirement from hidden truth.
- An entry already has an agreed utility plan: no new-request penalty.
- Player gives a cue before readiness: feedback is one coordination finding among the other skills.

This update specifies expected behavior; it does not claim that these grading checks or post-death input handling have been implemented or tested.
