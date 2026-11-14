# Shared contracts ? proposed v0

**Status: proposed, not frozen.** Person 3 coordinates schema definitions; all three confirm them at kickoff. These examples are starting points, not tested engine APIs. The brief's requirements take precedence.

## Selected natural-language boundary

Use [communication contract v1](COMMANDS.md) and its JSON Schema for new player messages. The user selected this interface for implementation: flexible phrasing becomes a validated report, flash command or coordinated swing, with explicit timing and lifecycle results. Person 3 interprets/reports; Person 2 validates/executes; Person 1 supplies mechanics/markers. Other contracts below remain proposed; the old fixture is not silently upgraded.

## Conventions to confirm

Proposed coordinates: meters, Y up, Godot Vector3 serialized as [x, y, z]. Integer ticks are authoritative; simulation timestamps can be derived from the configured rate. Use stable string IDs, schema_version and named unknown-region handling. The fixture's 60 Hz is illustrative and does not pin runtime settings.

Copy values into policy inputs; never pass live nodes or global truth dictionaries. Private recording access and bot subscription access are separate.

| Contract | Producer -> consumer | Required concepts |
|---|---|---|
| Region registry/graph | Person 1 -> Persons 2/3 | ID/name, bounds/center, neighbors, travel times, unknown fallback and version |
| Gameplay event (privileged) | Person 1 -> perception/private recorder | ID/tick/type, actor, position, payload |
| Observation (bot-local) | Person 2 -> beliefs/policy | ID, bot, event/availability tick, source, copied content, confidence, speaker/provenance |
| Callout | Person 3 -> delayed delivery | ID, speaker, type, region, count, hedge, event tick |
| Belief query | Person 3 -> Person 2 | Bot-local enemy-region probabilities, trust, available evidence IDs |
| Actor intent | Person 2 -> Person 1 | Actor, movement/aim/fire/reload/utility/defuse intent; no hidden target tracking |
| Decision record | Person 2 -> Person 3 | Tick, bot, goal/action, evidence IDs, reason, branch/fallback |
| Archive (privileged) | All -> Person 3 | Version/config/seed, inputs, snapshots, truth and per-bot observations |

## Tick ordering and delay

Proposed order: collect physical events -> make due observations available -> deliver due callouts -> update belief -> plan -> execute actions -> record. Ensure logs distinguish actual event time from availability time. Freeze exact ordering before implementation. No policy consumes an observation early.

## Public information

Create an explicit allowlist. Own health, ammunition and actor pose are own-state inputs. Static map layout may be known. Whether teammate elimination and spike/timer signals are globally public must be decided and documented. An evaluator seeing a hidden position is not grounds to notify a bot.

## Synthetic handoff fixture

examples/interface_fixture.json illustrates one player callout delivered to one bot and a later decision citing it. It is not a pro round, schema standard, trained policy or fairness test suite. The documentation checker only verifies basic example consistency.

Person 1 should expose actor movement/action execution and a map query adapter. Person 2's policy consumes a belief provider and delayed observation provider. Person 3 must be able to replay observations without loading the 3D world. Avoid hard dependencies on another lane's scene internals.

## Required fairness tests when implemented

1. Evidence IDs belong to the deciding bot and are available by the decision tick.
2. Policy dependencies cannot access hidden truth, scene lookups or live target nodes.
3. Moving an unseen enemy while holding all allowed inputs and seeds fixed leaves the policy decision unchanged.
4. Smoke/flash and reaction delay suppress or delay observations for every actor.
5. Fallback stays inside the same information boundary.

Person 2 now tests delayed evidence, private-input boundaries and hidden-state perturbation in isolated modules; see [the runtime guide](PERSON2_EXECUTOR.md). Scene-based smoke/flash perception and full-game checks remain pending.
