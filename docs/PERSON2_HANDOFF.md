# Person 2 handoff - perception, bot behavior, scenario runtime

## Priority override — six-hour final sprint, 2026-11-15

### Latest: local voice-to-engine integration

Implemented [the synthetic voice game](../bots/VOICE_GAME.md): PC microphone/STT and
Person 3 interpreter feed a localhost-only copied-data bridge. Godot stamps real
receipt ticks and uses the existing delayed inbox, beliefs and physical controller.
No wall-time backdating, shared-main replacement or invented seven-region mapping.
New internal host/scene protocol and runtime `invalidate_model_goal()` are owned
integration seams; shared observation/comms/belief schemas are unchanged.

Actual full-goal spike did not meet the current context budget (Llama and smaller
Qwen timeouts; constrained-goal checks still fail). Per authoritative sprint go/no-go,
default is **LLM interprets, deterministic planner decides**. Experimental goals are
opt-in, unaccepted, and logged; the full-goal fixture stays nonzero when they fail.
Goal expiry was not loosened to manufacture a pass. See exact results/limits in the
voice-game guide. Source Person 3 belief `57f809d` remains pinned for compatibility;
coordinated trust-field/full-acceptance alignment still remains.

Fresh automated evidence: 552 default/cross-lane assertions; existing FPS baseline
41; new socket fixture initially 19; 3 Python boundary tests; real local-model
interpret-only engine fixture passes actual delayed report/physical movement.
Recorded-boundary audit of that run passes 33 contexts, 28 changed decisions,
157 deliveries and one model record. This is not full-game fairness. Final socket
HUD/disconnect checks pass **22**, Python boundary/capture tests pass **4**.
User has been offered the live spoken game test; no new human in-engine success is
inferred from the earlier standalone microphone test. Root/shared source and Person
3 implementation remain unchanged. Next: spoken game acceptance, source/schema
coordination and the inherited seven-region scenario/world work.

The user explicitly makes `docs/FINAL_SPRINT_PERSON2.md` on Person 3 commit `4c85f39`
the highest-priority handoff. Person 1 has left; Person 2 owns GPU/model/STT runtime,
inherited world/greybox/spawning, scenario authoring and live engine integration.
Person 3 supplies non-GPU glue, logging/fairness and demo support. Older ownership,
trust-field and schedule instructions below are historical where they conflict.
Main already contains PR #4 at `8712f7d`; no further merge of that PR is needed.

First step completed: [actual GPU capability results](CAPABILITY_SPIKE.md).
Llama 3.1 8B Q4_K_M on the 16GB RTX 4060 Ti runs 100% GPU; IPv4 interpreter warm
median 0.590s, eight semantic smoke checks correct with no fallback. Supplied broader
runner exposes ambiguity/hedge limitations documented in that report. Next: real
goal-selection measurement and live mic/STT/bridge. Full LLM-decides viability and
spoken-comm acceptance remain unverified. Preserve the deterministic fallback.

Next-step PC setup: [live microphone guide](../bots/LIVE_VOICE.md). Whisper small.en
CUDA/float16 and local Llama successfully process synthetic speech (0.668s STT,
1.298s audio-to-proposal). Windows default input is the Razer headset. A separate
push-to-talk acceptance window has been opened at the user's selected default mic.
First human sample is confirmed by the user: “two on heaven” -> “2 on heaven.” ->
b_heaven/count 2/sure, model source, 0.285s STT and 0.881s total after release.
All five suggested human calls have now completed: user confirms the only wording
error is cue -> queue, with correct on_cue interpretation. All five semantic outputs
match; median STT 0.138s, median release-to-interpretation 0.718s, no fallback.
Raw microphone audio is not saved. Broader accuracy is not established.
Person 3's newest `b84cc93` interpreter/log/pipeline/audit tests pass 47 checks in an
isolated snapshot. No Person 3 source changed. Its published pipeline still has
hedge-weighted beliefs, future-tick immediate headless application, and no local
LLM goal-generation implementation: do not call it a completed live-game bridge.
The current PC tool emits proposals only. Real goal prompt/timing, monotonic game
clock/delayed delivery and full-acceptance alignment remain integration work.

This is the current Person 2 work plan, refreshed after the user confirmed the correct map and visible teammate. Use it with [the project brief](../callout_trainer_brief.md), [decisions](DECISIONS.md), [ownership](TEAM.md) and [actual implementation records](../bots/PERSON2_HANDOFF.md). Older appended handoff records describe their original implementation snapshots.

## Current information-session result - 2026-11-15

### Continuation: causal delivery regressions and own-death HUD

Started clean at `b7edb7f`; fetched refs and verified PR #4 is draft/mergeable with passing checks at that head. The user subsequently **authorized merging to main after validation**, superseding older no-merge directions in these historical records. Preserve the lane branch and do not mark Person 2 complete.

Changed only `scenes/bots/teammate_info_panel.gd`, `tests/person2/{scene_perception_smoke,teammate_hud_smoke}.gd`, sensor/FPS guides and Person 2 handoffs. The HUD now uses existing copied `physical.reason=actor_dead` to show teammate down/inactive vision while the player survives. It preserves last-seen memory and normal restart/round-ended presentation. No new schema/model input or sensing/action behavior changed; runtime, motion/combat, runner, scenario, shared mechanics/map/player and Person 3 source remain untouched.

Added real inherited-scene regressions for five rapid clear/occluded torso locks before prior reaction delays finish, across seeds 7/73/191. Checks assert all ten aim/loss deliveries remain causal, unique and actually available; continued occlusion cannot renew evidence. Real shared-health target death preserves only legitimate pending pre-death aim and one ordinary delayed loss, without disclosing a kill/cause/hidden location. The HUD fixture kills the actual teammate while the player survives, then verifies inactive status, retained memory and reset.

Direct official Godot 4.4.1 (`49a5bc7b6`) checks: pre-edit `--perception-smoke` **125 pass**; final `--perception-smoke` **139 pass** and `--hud-smoke` **36 pass**, exit 0. Both final focused commands explicitly use `--person1-ref 487ad73 --person3-ref 57f809d` and print both local shared wave/player overlays. Initial restricted execution stopped at Windows certificate-store access; approved execution outside that sandbox passes without filtering errors or changing timeouts. Broader pre-merge results are recorded in the final entry below. Known shared navigation-bake mesh-readback warning remains. No new human playtest, microphone/model, rendered capture or exported-build test.

Fetched Person 3 now reaches `4ee6a69`, inspected read-only: grounded interpreter/vocabulary and decision logs are published, as are first-pass VOD annotations. This supersedes earlier statements that those files are absent. The annotation still labels source title/channel unverified, annotator placeholder and team review/region freeze pending; do not treat its event/year or map vocabulary as independently accepted here. No annotations or Person 3 implementation were imported. Existing belief source is unchanged from tested `57f809d`, with full-acceptance alignment still owned by Person 3. Next: consumer review/live voice-to-runtime bridge and real model prompt/latency audit, human information/utility/action acceptance, shared bootstrap/nav review, and coordinated objective/scenario work after vocabulary/source review. Defuse audio and full-region coverage remain unfinished.

**Final direct pre-merge verification for this continuation:** `validation/run_person2_tests.py --godot <installed 4.4.1 console> --person1-ref 487ad73 --person3-ref 57f809d` passes **552** assertions (505 owned: 183 command, 74 planner, 92 sensor, 77 motion, 23 intent, 12 flash, 44 combat; 47 optional: 10 belief, 9 sensor/belief, 28 shared motion). With the same pinned refs, `--perception-smoke` **139**, `--hud-smoke` **36**, `--first-person-smoke` **41** and `--action-smoke` **46** pass, each exit 0. The original `--demo`, `tools/check_repo.py` and whitespace checks pass. These are fresh runs on this continuation's source, not historical or separately attributed totals. Installed executable paths are unchanged from the exact commands below. All FPS modes print both local overlays. No script/engine errors in passing runs; known bake warning remains. Publication/merge outcome is recorded in the session response after GitHub checks; authorization is not a claim that a merge already happened.

Finalization checkpoint: the subsequent combat handoff also requests delayed `enemy_aim` (only actually visible copied torso point) and `enemy_lost` (loss of usable torso sight), leaving regional enemy_seen unchanged. The producer is added with six-tick aim refresh, ordinary reaction delay, one loss per recognized lock and per-enemy causal availability. Consumer agreement: event-time/delivery validation, 30-tick freshness cap, current own blind/smoke fire guards and opt-in combat. The action agent owns runtime/combat modules and authored lateral routes; its in-progress edits are preserved and excluded from this information commit. Final focused validation for this additional producer is recorded in the next verification entry; earlier 685-check results below predate it. Exact examples/limits: [combat evidence contract](../perception/README.md#agreed-delayed-combat-evidence).

**Final focused verification:** on the action agent's now-committed `b06cd3d` base, final `--perception-smoke` passes **125 assertions** and `--hud-smoke` passes **33**, both exit 0, official Godot 4.4.1 / Person 1 `487ad73` / Person 3 `57f809d` plus the explicit local wave/player overlay. Torso-only visibility, no coordinates behind partial cover, copy isolation, causal delayed loss, smoke/blind suppression/recovery, live entry release and unknown-region recovery are covered. One parallel run exceeded the 45-second budget; the final isolated scene run passed without changing that timeout or filtering errors. Documentation and staged whitespace checks pass. The action owner's `b06cd3d` handoff separately records 505 default + 41 FPS + 46 action assertions passing and supersedes its earlier viewport failure; those are attributed results, not additional runs by this information session. All of its commits/source remain preserved. No new human playtest is claimed.

The user split concurrent work: this session owns information/perception/delivery/HUD; the other session owns action logic and its separate harness. Preserved action commits `3c6085d`, `47fa755` and `8c33f58` without editing their motion/action files. The exact runner agreement permits only added action modes/files/scene selection and preserves existing modes; the other agent included the already-present shared-wave overlay block by explicit agreement.

Fixed lost visual evidence in unnamed/overlapping map space: the adapter now delivers delayed `{type: "enemy_seen_unknown_region", enemy_id}` rather than discarding a physically visible enemy. The private sentinel never leaves the adapter; no region/coordinate is invented. Named sightings remain unchanged. This new internal content reaches copied contexts/HUD but is not applied to Person 3's region-only belief handler; consumers must handle unknown location explicitly. The HUD also marks an ended 45-second round as inactive/press F, rather than displaying frozen perception as ready. Normal smoke occlusion and delayed reacquisition remain enforced.

The user explicitly answered **"Blind as it passes actors"**. This authorizes the small shared `utility/blind_wave.gd` / `scenes/player/player.gd` correction: real traveling waves now affect teammate and player once per source, retaining existing radius/facing/through-wall/duration rules and excluding actors behind the launch plane. Person 1 should review/adopt those two files. FPS launch/tests explicitly overlay and print the local versions, rather than silently loading old endpoint-only scripts from the frozen base ref. A typed registry membership error exposed by mixed flashes/waves was fixed using instance-ID lookup. Actual G-controller cast, pre-detonation blindness, once-only application and caster/incoming-player behavior are tested.

Action consumer agreement is now live: delayed **seen-only** `{type: "player_entry", actor_id: "player", entry_id: "entry"}`. Static scenario `player_entry_sensing` supplies a validated region/forward direction. Actual player displacement/velocity, FOV, collider LOS, smoke, blindness and exposure gate the independently seeded producer. Stationary players/teleports/anonymous heard footsteps never become release cues. Existing executor checks readiness/matching identity/entry and acts only after actual delivery. No executor/planner/motion/model implementation changed in this session. Exact fields/examples/limitations: [perception guide](../perception/README.md#information-recovery-and-action-consumer-additions).

Actual official Godot `4.4.1.stable.official.49a5bc7b6`, read-only Person 1 `487ad73` / Person 3 `57f809d` plus the two printed local shared overlays:

- Required owned/cross-lane runner: **506 pass** (459 owned: 183 command, 72 planner, 92 sensor, 77 motion, 23 intent, 12 flash; 47 optional integrations). This also cleanly validates the action agent's committed unit additions that previously hit its certificate-store restriction.
- `--perception-smoke`: **106 pass**, including actual clear/smoked/blinded/out-of-FOV player entry and delayed evidenced follow-player release, wave travel and existing fairness regressions.
- `--first-person-smoke`: **40 pass**.
- Rendered `--hud-smoke --hud-capture <PNG>`: **35 pass** (33 functional plus two PNG saves), including unknown-region smoke suppression/fresh reacquisition and actual G-wave teammate/shared-player behavior. Captured layout inspected.
- Combined **685 functional assertions plus two rendering checks**, exit 0. Original `--demo` passes. Known shared bake mesh-readback warning remains; no script/engine errors in passing runs. The first optional cross-session `--action-smoke` reached 32 assertions with only viewport-containment failure; relayed to the action owner, whose files remain untouched.

No new human gameplay, actual voice/model or export pass. New source changes stay in information-owned paths except the explicitly user-approved two shared wave/player files. No shared schema, belief/full-acceptance implementation, shared map/main/settings or bot logic changes here. Remaining dependencies: action-panel layout/acceptance with its owner, Person 1 review of wave/bootstrap/nav, Person 3 voice/model/log/full-acceptance alignment, delayed combat-aim contract and verified annotations. Same branch/draft PR #4; never merge to main.

## Latest smoke follow-up - own awareness and HUD

User requested assurance against smoke vision, then explicitly asked that the UI show being smoked off versus inside smoke. Preserved the interrupted turn's natural-smoke regression work. Live sight blocking already used active-smoke segment geometry; it remains intact. Added cached own `inside_smoke`, `view_smoked_off`, `smoke_view_known` flags to `SceneSensor.own_status()` / existing snapshot. Own eye occupancy and a target-independent forward ray ending at the first world wall drive the HUD's **IN SMOKE** / **SMOKED OFF** states and amber Vision restriction. The forward assessment is unknown while blinded/down. No hidden opponent location, full-region claim, shared schema or model context change.

Tests now cover natural shared smoke deployment/expiry between actors, listener inside, enemy inside, all three blocked sight samples, pre-smoke delayed evidence, stale memory with no refresh, natural recovery, hidden smoke behind a wall, target-independent flags, actual unattended HUD labels and clearing. Godot 4.4.1 with Person 1 `487ad73` / Person 3 `57f809d`: scene perception **83** pass; default/cross-lane **477** pass; FPS **40** pass; rendered HUD **24** pass (**22** functional + two PNG saves). This is **622 functional assertions plus two rendering checks**, exit 0. Actual inside/smoked-off captures inspected; known shared bake warning remains. No new human gameplay/voice/model test or change to teammate-owned source. [Manual smoke test and exact fields](../bots/FIRST_PERSON.md#test-teammate-perception-in-the-hud). Existing integration/full-acceptance/physical scenario dependencies remain unchanged.

## Latest follow-up - teammate information HUD and movable test enemy

User requested visible teammate knowledge, blind feedback and enemy movement controls for manual testing. Added owned `scenes/bots/teammate_info_panel.gd` and FPS scene wiring, static test enemy presets in `scenarios/b_site_coverage.json`, `tests/person2/teammate_hud_smoke.gd` and runner `--hud-smoke` / optional `--hud-capture`. The panel reads existing copied runtime snapshots only; it shows delivered last-seen memory/age, coarse sound, accepted comms, action/charges and own blind countdown. No runtime interface, policy input or shared schema changed.

F6 moves/revives the red labeled enemy to entry; F7 to the room; arrows move it through shared actor physics; P places it on safe floor under the camera crosshair; F8 creates a repeatable shared flash with actual fuse/LOS/duration. Buttons work with the mouse released. These privileged test controls do not inject reports or force sensory state. All code/presentation stays in Person 2's owned inherited scene; no shared main/map/player/utility or Person 3 UI source was edited. [Exact launch and manual checklist](../bots/FIRST_PERSON.md#test-teammate-perception-in-the-hud).

Actual automated Godot 4.4.1 results using the existing pinned executable and read-only Person 1 `487ad73` / Person 3 `57f809d`: `--hud-smoke` **18 pass**, `--perception-smoke` **45 pass**, `--first-person-smoke` **40 pass**, default/cross-lane command **477 pass**. Combined **580 assertions**, exit 0. Optional rendered `--hud-smoke --hud-capture <PNG>` **19 pass** (same 18 plus PNG save); the actual captured layout was inspected. Known shared bake mesh-readback warning remains. These are automated tests/rendering inspection, not a human gameplay or voice/model pass. Remaining cross-lane dependencies and ordered work below are unchanged.

## Current continuation result - live sensing and physical flash

The unfinished November 14 checkpoint below is preserved as history. Its dirty work was retained and completed on `person-2/bot-perception`, above merge `28950f4` of main `487ad73`; publication stays on draft PR #4. No shared actor, map, main/player scene, utility, project setting, schema, or Person 3 source was edited.

- Live `perception/scene_sensor.gd` is now compiled and tested against the actual inherited FPS scene/current map. All four checkpoint review fixes are implemented: velocity plus displacement for running, conservative off-nav listener suppression, explicit blind-wave identity, and sensor diagnostics in decision telemetry. Callbacks disconnect on disposal/replacement/reset.
- Due sensory envelopes feed the real inbox and supported sightings feed Person 3 beliefs. Plain contexts contain only promoted observations; delayed evidence is never reinterpreted as a live position. Hearing remains coarse/logged, with no fabricated belief likelihood. See [the sensor guide](../perception/README.md).
- After the sensor gate, added `bots/flash_controller.gd` and motion/runtime wiring for one authored `flash_entry` charge per synthetic round. Actual shared flash release is atomic and deduplicated; cancellation/expiry before release preserve inventory, failed spawn refunds, and reset replenishes the charge. See [command semantics and consumer seam](../bots/FIRST_PERSON.md). Completion means physical release, not a successful blind.
- Proposed consumer additions: `observation_delivered(observation, delivery_tick)`, `decision_recorded.errors`, and copied snapshot `observations`, `own_perception`, `flash_count`. Context keys and comms.v1/observation/belief schemas are unchanged. Persons 1/3 should review the adapter/consumer details in the PR before shared adoption.

Actual automated commands use the exact Python/Godot paths in the checkpoint. Official Godot `4.4.1.stable.official.49a5bc7b6`, read-only Person 1 `487ad73` and Person 3 `57f809d`:

- Before fixes, `--first-person-smoke`: 29 assertions pass after approved outside-sandbox execution. The initial sandbox import failed on Windows certificate-store access and was not counted as a pass.
- `--person1-ref 487ad73 --person3-ref 57f809d`: 477 pass (430 default: 174 command + 72 planner + 92 sensor + 57 motion + 23 intent + 12 atomic flash; 47 optional integrations: 10 belief + 9 sensor/belief + 28 shared motion).
- `--perception-smoke`: 45 pass, including actual wall/utility/audio/nav mechanics, event-time occlusion cutoffs, delivered sight evidence in beliefs/model goals, copied-context mutation isolation, newly generated context/decision equality under unseen live-node perturbation, exact sensor errors and pending-evidence/callback reset.
- `--first-person-smoke`: 40 pass (the prior 29 plus physical flash staging/cancel/expiry, delayed cue/now release, actual projectile, completion, duplicate/depletion handling and replenishment on inherited reset). Total across these commands: **562 assertions**, exit 0. The older 29-check checkpoint result is not the result of the new fixture.

The known shared navigation-bake mesh-readback performance warning remains. Fixture timer cleanup was corrected; no cleanup warning remains in the live-sensing pass. Default CI runs owned suites and the synthetic demo; inherited-scene/cross-lane checks are local, not claimed CI results.

**Manual results:** no new human playtest, voice/model run or export test. The user's earlier correct-map/visible-teammate report remains startup evidence only.

**Concrete Person 3 dependency:** an exploratory conflicting-report check showed the imported multiplicative belief model can keep a new valid player report outweighed by earlier sight evidence. This is in addition to its documented numeric hedge weights. The owned sensor fixture tests an uncorroborated wrong report from a fresh belief; it does not claim full-acceptance/correction alignment. Person 3 knows/owns that requirement. Do not fix it by consulting truth, rewriting that lane, removing the assertion's meaning, or building another voice/model system.

Next ordered work: coordinate Person 3's voice/model/log consumer and full-acceptance fix; add permitted delayed player-entry sensing for follow-player release; implement shared defuse and combat only after agreeing a delayed last-observed aim payload. Then physical scenario feasibility/dry runs and observation-driven branches, using Person 3's structural helpers/verified notes. PVS/full-region clear, defuse audio and full safety diagnostics remain unfinished. Person 1 still owns shared bootstrap/nav production alignment and mechanics; verified pro notes remain unavailable. Run the human sight/hearing/smoke/flash/navigation/reset checklist before claiming gameplay acceptance.

## Current product rules

- The player controls a character in first person and communicates by voice. No player comm menu; existing menu helpers remain test/fallback code.
- Person 3's free/local grounded LLM interprets speech and sets teammate goals. No training is required. Person 2 validates and physically executes those goals.
- **The teammate always fully trusts valid, delivered player comms, including wrong calls.** No credibility score, history penalty, corroboration prerequisite or numeric hedge-based credibility discount. Preserve the player's explicit uncertainty/last-seen meaning rather than inventing precision. Clarification, delivery delay, provenance, command lifecycle and physical feasibility still apply. Wrong information can lead to a bad tactical outcome; it does not reduce acceptance of later calls.
- An empty `trust: {}` field may remain for snapshot compatibility. It has no behavior or scoring meaning; removing it is not a priority or a reason to change the shared schema.
- Grading/debrief and counterfactual are deferred until the core voice-to-reaction loop works.
- Continue with synthetic data until Person 3 supplies verified VOD/year/round/timestamps and actor notes. Do not invent pro positions or actions.

**Implementation gap:** Person 3's currently imported belief module at `57f809d` still uses numeric hedge strengths. Person 3 must align its belief/interpreter/model behavior with full acceptance. This requirement/documentation update does not edit that lane's source or claim the behavior has already changed. Keep explicit uncertainty as content, not a player-credibility penalty.

## Continuation checkpoint - 2026-11-14 (unfinished live sensing)

The user requested this checkpoint for a new Codex window. **Resume the existing dirty worktree; do not reset, clean, discard, or overwrite these changes.** The immediate task is to finish and verify live scene perception, not to start another scene or voice interpreter. Person 3 has been informed that trust/credibility weighting is no longer wanted; keep the full-acceptance rule above and leave that lane's implementation to Person 3.

### Branch, source revisions and actual results

- Branch: `person-2/bot-perception`; existing draft PR #4. Local HEAD `28950f4` merges main `487ad73` (Person 1's walk-in circular divot). Both lanes' appended handoff entries were preserved in the documentation conflict. At this checkpoint the branch is two commits ahead of its remote; the merge and current source edits have not been pushed.
- Read-only Person 3 dependency remains `57f809d`. No Person 1 or Person 3 source was edited to implement sensing.
- The new main caused two FPS navigation assertions to fail at the old coverage marker. Moving only the Person 2 marker from `[0,0,3]` to `[-1,0,3]` restored **29/29 first-person smoke assertions**, exit 0, on official Godot `4.4.1.stable.official.49a5bc7b6`. This pass was **before** the live-sensing changes below. Do not report it as validation of those changes.
- **Current live-sensing source has not been compiled or tested.** Historical 494-check results apply to the earlier map/source snapshot. The known runtime mesh-readback bake performance warning remains.
- Human evidence remains: user confirms the correct map and visible teammate. No new sight/hearing/utility/voice/model or exported-build playtest was performed.

### Existing uncommitted implementation to inspect and continue

- New **untracked** `perception/scene_sensor.gd`: privileged real actor/opponent registry, region mapping, shared active-smoke segment checks, shared flash/blind-wave duration checks, narrow weapon/utility signal subscriptions, run-footstep sampling and navigation-path hearing through the existing sensor kernel. Live Nodes/RIDs/positions remain private; emitted observations use round-prefixed IDs. It disconnects its callbacks on disposal. Ensure this new file is included in any eventual commit; it must not be lost when switching windows.
- `bots/teammate_runtime.gd`: attaches the sensor, enqueues delayed sensory envelopes, applies due sightings to Person 3 beliefs, exposes only promoted/due copied observations, adds `observation_delivered(observation, delivery_tick)` and own-blind snapshot status, and disposes the adapter on reset. Hearing is available/logged but is not fed into the current unsupported Person 3 belief handler. Model-context keys and comms.v1 remain unchanged; the new signal/snapshot additions are a proposed consumer seam to document/review.
- `scenes/bots/first_person.gd`: attaches the adapter to the existing inherited Person 1 scene's real teammate, target, utility and player. No replacement map/main/player scene was created.
- `scenarios/b_site_coverage.json`: corrected coverage marker plus explicit seeded sensing configuration. `tests/person2/first_person_smoke.gd`: corresponding marker expectation and context checks that distinguish sensory records from comms. `validation/run_person2_tests.py`: copies the new adapter into disposable FPS projects.

### Immediate next work (before further bot intelligence)

1. Inspect the source and run the existing FPS smoke to catch GDScript/import/runtime errors. Do not suppress engine errors merely because assertions print a pass marker.
2. Review unfinished adapter details: require real horizontal running velocity as well as displacement so fixture teleports do not become footsteps; conservatively handle an off-navigation listener instead of snapping arbitrarily far; identify blind waves explicitly rather than relying on a generic Node3D-vs-RigidBody distinction; preserve sensor errors in decision telemetry. These are review items, not implemented fixes.
3. Write a real inherited-scene perception smoke fixture and runner mode (suggested `--perception-smoke`; **neither exists yet**). Verify visible target -> delayed sighting; wall/active smoke/blind -> no new sightings; inactive/falling smoke collider does not falsely occlude; flash LOS and through-wall blind-wave semantics; actual weapon/run sounds, quiet walk/crouch, path-distance hearing, round reset/disconnection, plain copied contexts and evidence availability. Perturb an unseen opponent and verify allowed policy inputs do not gain hidden information. Existing kernel tests alone do not establish live-adapter fairness.
4. When testing loss of LOS, allow pending observations sampled before occlusion to arrive legitimately; assert on each observation's `event_tick` relative to the occlusion cutoff. Never reinterpret delayed evidence as a current live position.
5. Run meaningful default/cross-lane and FPS/new-sensing checks after fixes. Update this handoff, `bots/PERSON2_HANDOFF.md`, `docs/HANDOFFS.md`, the perception README and FPS guide with actual results. Then commit explicit owned paths and push the existing lane branch/PR; do not merge main or claim unfinished acceptance complete.

### Important adapter limitations and following dependencies

- Shared smoke creates a raw collision body before becoming active. The adapter excludes smoke bit 16 from kernel raycasts and uses the shared active-smoke geometry; test this deliberately.
- Current `enemy_seen` belief content must remain exactly `{type, enemy_id, region_id}`. Do not add live aim positions to it or silently change the shared schema. Combat needs an agreed delayed last-observed aim payload.
- Audio uses narrow actual Weapon.fired/Utility.deployed callbacks, never an unrestricted truth/event archive. Ignore utility's hard-coded thrower identity. Footstep cadence is a Person 2 sampling approximation; shared defuse audio is not connected. Sound timestamps are the actual next sensing tick, not reconstructed historical listener poses.
- No complete-region-clear/PVS evidence, live voice/model bridge, bot flash execution, follow-player release, combat/reload, defuse or verified scenario branches are completed by this checkpoint. Those remain the ordered work below after the sensor gate. Person 3 owns voice/interpreter/model/logging and full acceptance; Person 1 owns shared mechanics/bootstrap/navigation; verified annotations are still required for real pro scenarios.

### Exact local commands

~~~powershell
$pythonExe = 'C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe'
$godotExe = 'C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe'
& $pythonExe tools/check_repo.py
& $pythonExe validation/run_person2_tests.py --godot $godotExe --first-person-smoke
& $pythonExe validation/run_person2_tests.py --godot $godotExe
# Human launch (close old temporary game first):
& $pythonExe validation/run_person2_tests.py --godot $godotExe --first-person
~~~

The launcher reads latest locally fetched `origin/main`, freezes and prints its revision, and does not fetch itself. Godot may require elevated sandbox execution to read the Windows certificate store. The runner already uses a process-only exact-checkout safe.directory exception for Git reads; do not add a global exception. Consult git status before any staging/checkout and preserve all teammate changes.

## Ownership

- **Person 2:** perception/hearing/reaction delay; bot scenes/spawning; physical intent execution; deterministic fallback; executable scenario data/enemy baseline/reactive branches; physical feasibility and fairness/safety checks.
- **Person 1:** shared player/actor/weapon/utility mechanics, map geometry/regions/navigation, shared main scene/settings and export.
- **Person 3:** microphone/STT, interpretation, local LLM goals, working beliefs/full acceptance, exact prompt/output logging, annotations, shared schemas and structural scenario helpers. Grading/evaluation are later.

Stay on `person-2/bot-perception`. Preserve teammate edits; do not edit another lane's source to work around an integration dependency. The separate owned FPS scene inherits Person 1's main rather than replacing it.

## What exists now

- Person 1's current synthetic `b_site.json`: corridor, entry hallway/arch, deeper room and divot. It is not a verified real-site reconstruction. Current region IDs: `room`, `entry`, `corridor`.
- Person 2's [inherited first-person scene](../scenes/bots/first_person.tscn), reusable [bot actor](../scenes/bots/bot.tscn) and [owned coverage/spawn data](../scenarios/b_site_coverage.json). The launcher follows latest locally fetched main and prints immutable source revisions.
- Actual shared actor movement/health, coverage navigation and watched angles; delayed comm inbox/executor, command stage/swing/cancel/expiry, copied model-context/intent gate and deterministic fallback.
- A tested physics/navigation [perception kernel and live inherited-scene adapter](../perception/README.md); the checkpoint above records its original unfinished state. Current results are at the top of this guide.
- Person 3's fetched branch `57f809d` contains STT scaffolding, belief helpers and a structural scenario schema/validator/coordinate helper. STT target-machine results are unfilled; the grounded interpreter/model host and game bridge remain dependencies.
- Older 494-assertion runs are historical. Current continuation commands/results are above and in the appended lane handoff; automated results never establish voice/manual acceptance.
- **Manual evidence:** the user confirms the current map is correct and a teammate is visible. Movement feel, all bot interactions, utilities, real speech/model latency and exported-build behavior are not established by that report.

## Your next steps, in order

### 1. Wire live perception into the current FPS runtime

Automated live-adapter acceptance is now implemented and passing as described above. Human acceptance and the listed remaining sensing dependencies are still open. Keep these requirements when extending the adapter:

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

The current actor supports hold/coverage movement, authored swing staging/routes and tested physical flash release with atomic inventory/launch/completion. Next add permitted follow-player swing release, defuse, and shared rifle/aim/reload behavior based on delayed last-observed data. Keep one movement owner. Report actual completion/failure; do not convert a report into a forced push or claim a throw from merely issuing an intent.

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
