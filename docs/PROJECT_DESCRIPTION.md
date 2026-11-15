# Project description

## What we are building

Callout Trainer is a first-person tactical communication practice game. The player
speaks to a teammate that can act only on what it has seen, heard or been told after
reaction delay. Useful reports and coordinated commands change the teammate's working
picture and physical behavior. The goal is clearer communication: timely reports,
appropriate uncertainty, utility coordination, readiness and useful death reports.

It is a standalone Godot simulator. It does not connect to a game client, reproduce
professional outcomes or claim measured improvement in win rate or communication skill.
Later grading/debrief should explain information gaps; that is deferred work.

## The current experience

Use `validation/run_voice_game.ps1 -Lotus`. This launches a separate authored seven-region
greybox: `b_main`, `b_cubby`, `b_heaven`, `b_upper`, `b_pit`, `c_link`, `a_link`.
The original three-region map and root scaffold remain available and unchanged.

The source-role adaptation puts the player in Something/Yoru's role and the teammate
in f0rsakeN/Omen's role. PRX holds the plant against an FNC retake. At t0 the spike has
just been planted. All four unknown enemy starts remain `unknown` in source data;
there are no guessed enemy bodies or colliders waiting offscreen.

At +23s, the annotation first locates Chronicle/crashies in Heaven, kaajak in C Link
and Boaster in B Main. They spawn then, rather than at guessed plant-time locations.
Boaster's +16s smoke is not evidence of his position. He is first localized by a
recorded death; spawning him alive there is an explicit continuation adaptation.
No recorded death or win is forced. Source metadata/event/year and team review remain
unverified. All metric geometry and within-region coordinates are authored approximations.

The player can move, shoot and talk; cannot defuse their own plant. Retakers use shared
movement, rifles/damage and defuse interaction. A delivered sight can trigger an authored
flank branch. Elimination, detonation or defuse resolves the scenario; F restarts at plant.
Exact utility/cooldown reenactment and the teammate's complete annotated baseline remain
unfinished. Health/armor are currently simplified into shared health pools.

## Communication and decisions

```text
Right Ctrl + microphone
  -> local Whisper transcription
  -> grounded local Llama interpretation
  -> proposal over localhost TCP
  -> Godot stamps actual receipt tick
  -> delayed inbox and command validation
  -> belief / deterministic planner
  -> shared physical execution
  -> transcript, prompt/output and delivery/decision records
```

Voice is core, not a stretch. Typed inputs exist for developer fixtures only. The LLM
interprets reports and supported commands; ambiguous input should clarify instead of
inventing a target. Fast go/cancel cues bypass expensive interpretation while retaining
delivery/readiness checks. Normalized messages remain `comms.v1`.

The final-sprint handoff explicitly allowed a capability-driven fallback. Actual engine
goal calls missed the current context budget, so the selected configuration is **LLM
interprets; deterministic planner decides**. Experimental model goals are opt-in and not
accepted for the demo. Do not describe them as the working default or erase their failures.

Valid delivered player reports should be fully accepted, even when wrong. There is no
credibility/history feature. The pinned belief module still has a known hedge/full-
acceptance gap; coordinating that implementation is open work. Field removal and belief
behavior are separate issues and must not be conflated.

## Architecture and knowledge limits

Godot 4.4.1/GDScript runs physics and the shared actor/weapon/utility systems. JSON-defined
geometry creates visible surfaces, collision, named Area3D regions and navigation.
Person 2's inherited scenes provide spawning and bot orchestration. Local Python runs
Whisper, interpretation and telemetry outside the physics thread.

The model/policy receives copied available observations, local beliefs, allowed own-state
and static authored affordances. Privileged world access stays in sensing/spawning/
physical adapters. Enemy arrivals do not automatically become sightings or belief updates.
Smoke, flash, exposure, LOS and reaction delay still gate discovery. Model failures,
invalid goals, expiry or lost transport retain the information-limited safety policy.

Exact contexts/prompts/raw responses and evidence times are logged locally. Their audit
is part of the evidence, not a complete proof of all game paths. Evaluator truth must
remain separate from model inputs. Offline capability is intended; OS-network-disabled
and exported-build acceptance are not yet established.

## Current evidence versus unfinished work

| Evidence | Scope |
|---|---|
| Five standalone human mic calls interpreted correctly | One cue/queue spelling error; median after-release time 0.718s on that test |
| 552 default/cross-lane assertions | Command/planner/sensor/motion/intent/flash/combat and optional integrations |
| 139 live-perception checks | Inherited three-region scene, including smoke/blindness and causal delayed evidence |
| 31 new scenario checks | Plant start, +23s arrivals, physical traversal/combat, guarded elimination and reset |
| Seven Python tests | Authoring consistency and voice/model boundary checks |
| Real-model typed engine fixture + recorded-boundary audit | Delayed report, actual movement; audit of 33 contexts/28 changed decisions/157 deliveries |
| Rendered captures inspected | Visual/layout evidence, not human gameplay or spoken scenario acceptance |

Still required: human voice-to-scenario acceptance; source review; exact ally/utility
baseline; coordinated belief/schema alignment; complete safety/fairness coverage;
offline/export acceptance; backup video and demo rehearsal. Grading, truth/belief debrief,
belief-only counterfactual and evaluation comparisons remain deferred product goals.

Do not invent study citations, pro facts, time savings, transfer effects or win-rate results.
Keep the product buildable/demoable with local/free components. No training, paid API,
client memory access, extracted assets or replay-file scraping is required or permitted.
Do not redistribute model weights or source footage by accident.

## Current working arrangement

Person 1 has left. Person 2 owns the GPU PC/runtime and inherits world/spawning/engine
work. Person 3 supplies non-GPU interpretation/glue, belief/log/audit/annotation and demo
support. The sprint began with approximately six hours; this is not a renewable deadline.
Check the actual remaining time before choosing scope.

See [current handoff](PERSON2_HANDOFF.md), [decisions](DECISIONS.md), [team](TEAM.md),
[contracts](CONTRACTS.md) and [historical reference index](ARCHIVE.md).
