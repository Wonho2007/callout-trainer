# Person 2 knowledge planner

A deterministic, rule-based goal selector above the existing command executor. This is Person 2-owned code; no Person 1 actor/world files or Person 3 belief/annotation files were edited or merged.

## Implemented scope

- [knowledge_planner.gd](knowledge_planner.gd): select hold, cover, reposition, stop, or yield to an accepted player command.
- [synthetic configuration](../scenarios/synthetic_coverage.json): static authored coverage markers and tuning, explicitly not a real map or pro annotation.
- [planner tests](../tests/person2/planner_tests.gd): synthetic beliefs, provenance/age validation, priority, role/objective/reachability, stable selection and malformed inputs.
- [cross-lane test](../tests/person2/planner_belief_integration.gd): real Person 3 region_belief.gd plus Person 2 inbox/executor/planner, copied read-only into a disposable project when requested.

There is no machine learning, tactical search/rollout model, live enemy-transform access or visual perception in this increment. It does not claim real aiming, combat, navigation, smoke/flash sensing or a playable bot scene.

## Inputs

Create one planner per bot/round with the synthetic fixture's planner shape as a starting point:

~~~gdscript
const Planner = preload("res://bots/knowledge_planner.gd")
var planner = Planner.new(bot_id, authored_planner_configuration)
~~~

The configuration contains regions, coverage markers (id, watch_regions, roles, objectives), baseline_marker_id, baseline_watch_region, threat_threshold, freshness_ticks, heartbeat_ticks and switch_margin. Markers are safe authored destinations/angles, not enemy positions. Static watch_regions are planning affordances, not a PVS, a current visibility result or proof a region is clear.

The fixture thresholds are placeholders: 0.55 average enemy-slot mass, 10-tick freshness, 3-tick planning heartbeat and 0.10 switch margin. They intentionally make tests compact; convert/tune against the team's actual tick rate and scenario before gameplay. They are not measured Valorant timings.

decide(tick, belief_snapshot, own_state, executor.inbox, executor.active_command_snapshot()) returns copied output.

### Person 3 snapshot compatibility

The planner consumes the existing snapshot shape inspected at Person 3 commit 7a5375c:

~~~text
{bot_id, tick, enemies: {enemy_id: {region_id: probability}},
 trust: {speaker_id: reliability}, evidence_ids}
~~~

It does not modify probabilities, trust or grading. Distributions must contain the configured region IDs and be finite/nonnegative/normalized. Every evidence ID must already belong to this bot's inbox and have actually been delivered by the snapshot's tick. A snapshot tick of -1 with no evidence permits the initial prior.

Current scoring averages per-enemy marginal region probabilities. It is NOT the probability that any enemy is there, a count model, a win probability or a learned tactical value. This avoids assuming independence between Person 3's exchangeable enemy slots.

Fresh positive support comes from a referenced enemy_seen observation or report_enemy testimony at that region. Age uses event_tick, not delivery or prediction time. A newer snapshot/prediction, unrelated report or region_clear does not refresh an old enemy report. This is a conservative guard on the existing belief interface, not a replacement for Person 3's movement/decay model.

### Own-state allowlist

~~~text
{alive: bool,
 marker_id: known marker or "" while between markers,
 reachable_marker_ids: distinct known marker IDs,
 role: "hold" | "cover",
 objective: "none" | "entry" | "defuse"}
~~~

Objective is an assigned/explicitly permitted own-team goal, not a hidden opponent action. Reachability comes from static navigation plus this actor's known capabilities. Do not include enemy locations, world nodes or an unrestricted scene/archive object. The own-state shape is specific to this planner; it does not replace the existing command executor's snapshot.

### Accepted command priority

The executor now exposes active_command_snapshot(): a copied message ID, action, target, phase, expiry and evidence IDs, or {}. Pass this directly, not a new interpretation of raw player speech. The planner verifies matching bot-local command evidence and yields a goal of command while it is active. This goal does NOT re-dispatch the command; the existing executor remains responsible for its lifecycle and physical intents.

This is a trusted in-process integration boundary, not a cryptographic proof of an acceptance decision. Do not manufacture active snapshots from rejected or unresolved messages.

## Decision rules

1. Dead actor: stop.
2. Active accepted player command: yield routine autonomy to the executor.
3. Fresh, sufficiently strong belief: select a reachable authored coverage marker compatible with role/objective. Reposition only if not already there; otherwise hold or cover.
4. No useful fresh target: use the compatible baseline, another compatible reachable marker, or stop if none exists.

No report automatically initiates a push toward an enemy. The actor moves only to authored coverage markers. Replan on relevant input changes, age boundaries or the heartbeat. Prefer the current marker on exact score ties; otherwise tie-break by stable marker/region IDs. Switch-margin hysteresis resists small changes while allowing invalidated/unreachable/insufficient choices to be replaced.

Errors return ok=false with a reason and no decision, without committing planner state. Bootstrap code should stop autonomous motion and log the error, rather than dispatch an old autonomous target. Valid player-command execution is a separate controller path; a bad belief snapshot must not fabricate a command cancellation.

## Output

~~~text
{ok, errors, replanned,
 decision: {tick, bot_id, goal, target_id, watch_region_id,
            reason, evidence_ids, score}}
~~~

stop has null target/watch; command has the existing command target and null watch. Other goals use static marker/region IDs. The record can be logged as the planner's behavior trace. Own-state/config-driven decisions can legitimately have no observation evidence; do not fabricate evidence IDs.

hold/cover/reposition are autonomous GOALS, not new comms.v1 commands or implemented movement primitives. A Person 2 physical controller still needs to execute them through Person 1's actor/navigation APIs. Do not send them through the strict player-command schema.

## Wiring order

1. Queue trusted delayed observations into the existing executor.
2. Call executor.step once for the current tick with own physical state/feedback.
3. For reports, locate the original observation IDs in output.reports and apply only those accepted reports to Person 3. Do not feed rejected reports from inbox history into beliefs or mint replacement evidence IDs. Valid sensor observations are forwarded separately when due.
4. Query Person 3's snapshot, then call planner.decide with that snapshot and the current executor inbox/active snapshot.
5. Dispatch executor intents once. If planner returns command, do not also issue autonomous movement. Otherwise the autonomous controller consumes the selected goal.
6. Record the actual planner decision and command results. Coach/grade in Person 3's layer, not this policy.

The inbox must be released through the exact decision tick. Use its copied available observations for integration and audit, never its pending internals. The planner is not an automatic orchestration loop and does not update the belief model itself.

## Automated verification

Godot 4.4.1 stable and Python 3.10+; no third-party Python packages required:

~~~sh
python validation/run_person2_tests.py --godot "/path/to/godot"
python validation/run_person2_tests.py --godot "/path/to/godot" --person3-root "../callout-trainer-person3"
python validation/run_person2_tests.py --godot "/path/to/godot" --demo
~~~

Default runs the original command suite plus planner suite. Optional --person3-root copies three belief/adapter files read-only into the temporary test project and adds cross-lane checks. It never edits that checkout or requires merging it. Existing CI runs the new default suite automatically via the unchanged workflow.

The wrong-type, foreign/future/missing evidence, historical-delivery, hidden-state-perturbation and dependency checks support the current modules' input boundary. They do not establish end-to-end fairness once real sensors and physical adapters are added.

## Manual playtests and dependencies

**Manual playtests: none.** Headless assertions do not verify movement, sightlines, cover, player experience or communication-training benefit.

Remaining dependencies:

- Person 1: stable region/marker IDs, navigation/reachability and shared actor mechanics. Its current actor base was inspected read-only; no production adapter is wired here.
- Person 3: accepted report processing and belief snapshots; verified video annotations remain Person 3-owned, per the documentation now on main. The integration test verifies current API compatibility, not its complete lane.
- Person 2: real sight/hearing/smoke/flash sensing, autonomous goal-to-controller integration, pro-note conversion to baseline/branches, aim/combat tuning and scenario/safety validation.

Next in-engine milestone: an accepted enemy report changes a teammate's coverage goal and real movement/angle, with a trace, followed by a player command overriding that routine goal. Verify repeated messages, expiry and post-death player communication through the actual input channel separately.
