# Person 2 handoff - perception, bot behavior, scenario runtime

This is the current Person 2 work plan, refreshed after the user confirmed the correct map and visible teammate. Use it with [the project brief](../callout_trainer_brief.md), [decisions](DECISIONS.md), [ownership](TEAM.md) and [actual implementation records](../bots/PERSON2_HANDOFF.md). Older appended handoff records describe their original implementation snapshots.

## Current product rules

- The player controls a character in first person and communicates by voice. No player comm menu; existing menu helpers remain test/fallback code.
- Person 3's free/local grounded LLM interprets speech and sets teammate goals. No training is required. Person 2 validates and physically executes those goals.
- **The teammate always fully trusts valid, delivered player comms, including wrong calls.** No credibility score, history penalty, corroboration prerequisite or numeric hedge-based credibility discount. Preserve the player's explicit uncertainty/last-seen meaning rather than inventing precision. Clarification, delivery delay, provenance, command lifecycle and physical feasibility still apply. Wrong information can lead to a bad tactical outcome; it does not reduce acceptance of later calls.
- An empty `trust: {}` field may remain for snapshot compatibility. It has no behavior or scoring meaning; removing it is not a priority or a reason to change the shared schema.
- Grading/debrief and counterfactual are deferred until the core voice-to-reaction loop works.
- Continue with synthetic data until Person 3 supplies verified VOD/year/round/timestamps and actor notes. Do not invent pro positions or actions.

**Implementation gap:** Person 3's currently imported belief module at `57f809d` still uses numeric hedge strengths. Person 3 must align its belief/interpreter/model behavior with full acceptance. This requirement/documentation update does not edit that lane's source or claim the behavior has already changed. Keep explicit uncertainty as content, not a player-credibility penalty.

## Ownership

- **Person 2:** perception/hearing/reaction delay; bot scenes/spawning; physical intent execution; deterministic fallback; executable scenario data/enemy baseline/reactive branches; physical feasibility and fairness/safety checks.
- **Person 1:** shared player/actor/weapon/utility mechanics, map geometry/regions/navigation, shared main scene/settings and export.
- **Person 3:** microphone/STT, interpretation, local LLM goals, working beliefs/full acceptance, exact prompt/output logging, annotations, shared schemas and structural scenario helpers. Grading/evaluation are later.

Stay on `person-2/bot-perception`. Preserve teammate edits; do not edit another lane's source to work around an integration dependency. The separate owned FPS scene inherits Person 1's main rather than replacing it.

## What exists now

- Person 1's current synthetic `b_site.json`: corridor, entry hallway/arch, deeper room and divot. It is not a verified real-site reconstruction. Current region IDs: `room`, `entry`, `corridor`.
- Person 2's [inherited first-person scene](../scenes/bots/first_person.tscn), reusable [bot actor](../scenes/bots/bot.tscn) and [owned coverage/spawn data](../scenarios/b_site_coverage.json). The launcher follows latest locally fetched main and prints immutable source revisions.
- Actual shared actor movement/health, coverage navigation and watched angles; delayed comm inbox/executor, command stage/swing/cancel/expiry, copied model-context/intent gate and deterministic fallback.
- A separately tested physics/navigation [perception kernel](../perception/README.md). It is **not yet connected to the live first-person opponent/utility/audio registry**.
- Person 3's fetched branch `57f809d` contains STT scaffolding, belief helpers and a structural scenario schema/validator/coordinate helper. STT target-machine results are unfilled; the grounded interpreter/model host and game bridge remain dependencies.
- The latest prior automated run passed 494 assertions (465 default/cross-lane + 29 FPS). These are historical results for that implementation, not a fresh voice/manual test.
- **Manual evidence:** the user confirms the current map is correct and a teammate is visible. Movement feel, all bot interactions, utilities, real speech/model latency and exported-build behavior are not established by that report.

## Your next steps, in order

### 1. Wire live perception into the current FPS runtime

This is the next independent Person 2 coding task while Person 3 finishes voice/model work. Reuse `perception/perception_sensor.gd`; extend `bots/teammate_runtime.gd` and the owned scene adapters.

- Register the real opponent(s) only inside the privileged sensing adapter. Query live positions/collision/utility there, never in the planner/model context.
- Feed copied, delayed sight/hearing observations into the existing inbox. Forward supported due observations to the working-belief module, preserving IDs and actual delivery ticks.
- Connect smoke occlusion and flash/blind state through Person 1's shared utility interfaces. Do not claim full-region-clear evidence from partial visibility.
- Consume actual sound events through a restricted adapter. Preserve navigation-path hearing and quiet walk/crouch behavior; do not invent source identity or an exact unseen location.
- Keep player testimony fully accepted independently of whether the bot also saw the report. Lack of corroboration is not a credibility filter.

**Acceptance:** a visible enemy yields a delayed sighting; a wall/smoke/blind prevents it; an unseen enemy move cannot change allowed policy inputs. A player report still changes coverage after delay even if the teammate cannot see the enemy. Decisions cite only evidence actually available at that tick. Keep the in-engine scene test separate from the human playtest.

### 2. Connect the voice/LLM loop with Person 3 in parallel

The [existing seam and exact payload shapes](../bots/FIRST_PERSON.md) are ready for consumer review:

1. The scene emits `teammate_ready(runtime)` on each spawn/reset.
2. Person 3 captures/transcribes speech and interprets it; the trusted host sends a validated comms.v1 envelope through `submit_comm`.
3. Person 3 receives `policy_context_ready`, records the exact context/prompt/raw output and returns a parsed goal through `submit_intent`.
4. Person 2 executes through shared mechanics and emits `comm_result` / `decision_recorded`.

Review full-acceptance behavior with Person 3 along with the region vocabulary and proposed intent/log seam. Do not build a competing STT/LLM interpreter in Person 2's lane. No hidden truth, scene references or player-only scan/minimap data may enter model context. Model failures/illegal goals retain the deterministic fallback.

**Acceptance:** speaking a report such as "enemy in the room" changes the teammate's working picture and movement after actual delivery; a deliberately wrong but valid call is still accepted, and previous wrong calls do not reduce later acceptance. Explicit uncertainty is preserved. Ambiguous words produce clarification rather than guessed coordinates. Test command/cue timing, timeout/invalid-output fallback, post-death speech and reset on the actual model machine. Record measured latency and results, not estimates.

### 3. Complete physical actions through Person 1's shared mechanics

The current actor supports hold/coverage movement and authored swing staging/routes. Next add bot flash execution with atomic inventory/launch/completion, permitted follow-player swing release, defuse, and shared rifle/aim/reload behavior based on delayed last-observed data. Keep one movement owner. Report actual completion/failure; do not convert a report into a forced push or claim a throw from merely issuing an intent.

**Acceptance:** supported commands complete once; duplicate IDs cannot repeat an action. Death, expiry, cancellation, unavailable utility and unreachable/stuck paths stop or recover with a recorded reason. Bot combat uses the same physical rules as the player and does not track hidden live targets. Full acceptance does not make impossible commands executable.

### 4. Build enemy/scenario runtime from verified notes

Person 3 supplies source notes; Person 2 creates executable `scenarios/` data. Consume Person 3's structural schema/coordinate helper rather than duplicating it. Add physical navigation-time/LOS/utility/baseline validation, one observation-driven reactive branch, and conservative stuck/off-nav/OOD fallback. Keep authored alternatives distinct from observed pro actions. Use synthetic cases until real annotations arrive.

**Acceptance:** valid baseline/branch dry runs complete; an invalid scenario fails with a concrete reason. Hidden truth never drives a branch or fallback. Do not wait for source annotation to build independent physical tests.

## Current interfaces and constraints

- Existing comms.v1 shapes in [COMMANDS.md](COMMANDS.md) are unchanged. The `hedge` field can remain as explicit player wording; it must not be treated as a numeric player-credibility penalty.
- Current local model-goal seam supports hold/cover/reposition/stop on authored markers only. Broader goals need coordinated validation/execution support; do not silently assume trade/flash/defuse already work.
- Current addressed radio-style fixture delivery is 18 ticks; the local acoustic/team-radio range rule still needs agreement.
- Person 1's navigation map/bake cell alignment is accommodated only in the owned integration; the shared production fix remains coordination work.
- Shared schema/fixture changes need explaining to both consumers. Preserve copied-value boundaries and evidence IDs. An evaluator's truth is not a policy input.

## Run and record results

Use official Godot 4.4.1 stable. [FIRST_PERSON.md](../bots/FIRST_PERSON.md) has the exact installed paths and launch command. Automated commands:

~~~powershell
python tools/check_repo.py
python validation/run_person2_tests.py --godot <Godot4.4.1_console>
python validation/run_person2_tests.py --godot <Godot4.4.1_console> --first-person-smoke
~~~

Record exact command/version/result and what was tested. For nondeterministic model decisions, audit actual recorded model context/prompt/output rather than demanding identical reruns; keep deterministic perturbation/dependency/availability checks as additional tests. Human records include tester, build/scene, spoken words/actions and observed behavior. Never turn a headless pass into a manual or voice pass.

Update Person 2's row and append actual results/dependencies in [HANDOFFS.md](HANDOFFS.md); update [the continuation guide](../bots/PERSON2_HANDOFF.md). Keep publication on the existing Person 2 branch/draft PR; do not merge to main or overwrite teammates.
