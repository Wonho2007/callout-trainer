# Integration handoffs

Current Person 2 state: delayed inbox and command runtime implemented, with isolated Godot tests and a synthetic actor trace. No playable sandbox, sensor physics, language interpreter or evaluation results are claimed. Historical planning notes below describe the state when written; this does not alter another lane's progress.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 (Wonho2007) | Command/planner/perception plus authored-path motion controller tested; optional real shared room/actor/belief movement integration passes; [handoff](../bots/PERSON2_HANDOFF.md) | Wire controller/sensors to shared bootstrap; human visual gate; utility/scenario/combat work | Person 1 production nav cell alignment, agreed markers/bootstrap and utility/event interfaces; Person 3 live delivery/failure UI/hearing and verified notes |
| Person 3 | Not started | Verified video notes for Persons 1/2; schemas, fake run and evidence/time checks | Shared contracts; use synthetic fixture |

Update only the facts for your lane. Append a short handoff using:

- Branch/PR and owning lane:
- Changed files:
- Interface/schema changes and consumers:
- Actual checks run and results:
- Remaining work/dependency:
- Next integration step:

Do not record a check as passed when it was unavailable. The repository documentation check is not the leak test. Keep participant data, raw recordings and secrets out of handoff notes.

## Planning update: agent-led development

The brief and docs/AGENT_WORKFLOW.md now specify code-generated map geometry and short agent tasks for a beginner team. Person 1 starts with the synthetic room; Persons 2/3 integrate the communication fixture before site detail. Separate automated checks from human playtest evidence. No Godot implementation or manual playtest is claimed by this documentation update.

## Person 2: selected communication contract

Branch: person-2/bot-perception. Added docs/COMMANDS.md, schemas/comms_v1.schema.json and examples/comms_v1.json. Persons 2/3 must use the same action names, timing, expiry, deduplication and lifecycle rules; Person 1 supplies named entry/flash markers. Next: implement delayed observations and leak fixture before the executor. Speech, countdown synchronization and physical actions are not implemented or playtested. Documentation/schema checks are recorded with this handoff commit, not as gameplay evidence.

Validation: tools/check_repo.py and git diff --check passed; JSON Schema Draft 2020-12 check passed, 8 authored messages conform and 5 malformed variants were rejected. Reference IDs, expiry ordering and equivalent paraphrase payloads checked. No runtime behavior checks performed.

## Person 2: delayed observations and command execution

Branch/PR: person-2/bot-perception, PR #4. Added perception/plain_data.gd, perception/observation_inbox.gd, bots/command_executor.gd, validation/comms_validator.gd, validation/run_person2_tests.py, tests/person2/ and .github/workflows/person2.yml. Integration API and runnable commands: docs/PERSON2_EXECUTOR.md.

The executor emits stage/start_swing/throw_flash/stop intents plus lifecycle results and testimony for Person 3. It receives copied own-state and physical feedback, not world nodes. Person 1 must wire real movement/utility markers and feedback; Person 3 must apply reports and deliver normalized messages. No shared comms.v1 message fields changed. New internal observation/actor adapter shapes are documented in the runtime guide.

Validation: official Godot 4.4.1 headless suite passed 174 checks; the synthetic demo completed one swing, one mid-action report and one flash. Documentation checks and git diff --check passed. No visual playtest, speech or real physics validation. Next: wire those adapters in the synthetic room, verify one callout-driven swing and flash visually, then author baseline/branch scenario behavior.

## Product clarification: clear communication across skills

The user selected clear communication as the overall objective, with readiness, enemy reports, utility coordination before entry and useful death reports as examples. Added docs/COMMUNICATION_COACHING.md and aligned the README/brief/decision record. Person 2 supplies delivered-observation/result evidence; Person 3 grades opportunities/omissions and distinguishes parser failures; Person 1 supplies permitted player/death events and post-death input. No runtime/schema fields changed, no cross-lane code edited, and the broader grader is not claimed implemented. Next integration work must preserve player-knowledge limits and accept natural paraphrases.

## Person 2: knowledge-based planner (automated milestone)

- Branch: person-2/bot-perception; existing draft PR #4. Person 2-owned changes: bots/knowledge_planner.gd, bots/README.md, scenarios/synthetic_coverage.json, tests/person2/planner_tests.gd, tests/person2/planner_belief_integration.gd, plus small additions to bots/command_executor.gd, perception/observation_inbox.gd and validation/run_person2_tests.py. This handoff's Person 2 row and this appended note are the only shared-document edits in this increment.
- Behavior: select hold/cover/reposition from fresh bot-local beliefs and role/objective/reachability, stop when no feasible goal exists, and yield to an accepted player command. Decisions include reason, target/watch IDs and available evidence. Event-time freshness, stable ties, hysteresis and heartbeat prevent stale chasing and unnecessary oscillation. No world/scene handles enter this policy.
- Interfaces: consumes Person 3's existing snapshot shape; adds copied active_command_snapshot() on the executor and owner_id() on the inbox. No comms.v1 schema, Person 3 module, shared fixture or Person 1 project/actor/world file was changed. Authored planner configuration and the new planner own-state/output shapes are documented in bots/README.md; these do not silently replace the physical executor API.
- Read-only inspection: Person 1 origin/person-1/world-scaffold at a158bb3; Person 3 checkout/branch at 7a5375c, clean before/after the optional integration run. Person 3 retains video annotation ownership per main's de65f09 documentation. No teammate branch was merged, reset or edited.

**Automated checks actually run:** official Godot 4.4.1 stable via Python 3.14:

Python executable: C:/Users/Isoto/AppData/Local/Python/pythoncore-3.14-64/python.exe. Godot executable: C:/Users/Isoto/Downloads/callout-godot-4.4.1/Godot_v4.4.1-stable_win64_console.exe.

1. validation/run_person2_tests.py --godot <Godot4.4.1_console> --person3-root ../callout-trainer-person3: existing command suite 174 checks, planner suite 72 checks, real Person 3 belief integration 10 checks; all pass, exit 0. Total 256 checks. The optional runner copies Person 3 files read-only to a temporary project.
2. validation/run_person2_tests.py --godot <Godot4.4.1_console> --demo: original synthetic actor trace passes (one swing, one mid-action report, one flash).
3. python tools/check_repo.py and git diff --check: pass. Existing CI now automatically runs the added planner suite through the Person 2-owned runner; optional cross-checkout integration is local and not claimed as part of CI.

**Manual playtests:** none. No visual scene, real navigation/utility, smoke/flash perception, speech performance, training efficacy or full-game fairness validation is claimed.

**Remaining dependencies / next step:** Person 1 supplies aligned region/marker IDs, navigation reachability and physical feedback. Person 3 supplies accepted reports/current beliefs in the running game and verified annotation notes. Person 2 must implement the autonomous goal-to-actor controller and real sensors, wire these interfaces in a synthetic room, manually verify a report-driven coverage change and command override, then convert the verified video notes to baseline/branches and add scenario/stuck/fallback checks. The synthetic planner fixture is not a pro reconstruction.

**Publication/integration status:** pushed Person 2 implementation commit 1dccb18 to the existing branch. GitHub docs and Person 2 Godot checks passed (default command/planner suites plus synthetic demo). PR #4 remains draft and reports documentation merge conflicts with newer main changes. A non-mutating git merge-tree check identified README.md, docs/DECISIONS.md and docs/HANDOFFS.md; no working-tree merge was started. Reconciliation of shared documentation is a remaining integration dependency; it was not resolved by overwriting shared files or changing another lane's source. Optional 10-check Person 3 compatibility remains a local automated result, not a CI claim.

## Person 2: physics and navigation perception kernel

- Branch: person-2/bot-perception; PR #4. Added perception/perception_sensor.gd and perception/README.md, plus tests/person2/perception_tests.gd, physics_probe.gd and perception_belief_integration.gd. Updated Person 2's test runner, bots/README.md and this handoff's own row/note. No Person 1/3 code, project settings, schema or shared fixture was changed.
- Actual mechanics tested: FOV/range and multi-point PhysicsServer3D raycasts, walls/partial cover, smoke Area3D blocking (including observer inside smoke), blind-status suppression/recovery, continuous near/far recognition and refresh, seeded reaction delay, and NavigationServer3D path-distance hearing. Quiet footsteps, disconnected/off-mesh anchors and missing/unsynchronized navigation are handled explicitly.
- Privacy: registered positions/RIDs stay inside the privileged sensor. Only plain delayed observations leave it; the inbox prevents early consumption. Visual payload matches Person 3 enemy_seen. The new proposed sound_heard payload has only sound kind/distance class; it does NOT disclose source identity, coordinates or exact region. Person 3's current belief module does not yet handle hearing; no sound-based belief improvement is claimed.
- Integration assumptions: Person 1's inspected layer bits are world=1/player=2/bots=4/regions=8. Smoke bit 16 in tests is a proposal requiring coordination, not a root-project edit. Shared flash mechanics must supply blind_until_tick. Nonquiet hearing needs synchronized navigation and walkable acoustic anchors; no Euclidean fallback. No PVS/full-region negative-evidence implementation is claimed.

**Automated checks actually run:** official Godot 4.4.1 stable, using the executable/Python paths recorded above.

1. validation/run_person2_tests.py --godot <Godot4.4.1_console> --person3-root ../callout-trainer-person3: command 174, planner 72, real physics/navigation perception 92, existing Person 3 belief integration 10, actual-raycast-to-Person-3-belief-to-planner integration 9; all passed, exit 0. Total 357 checks. Person 3 code was copied read-only into a temporary project.
2. Original synthetic command demo (--demo), documentation check and git diff --check pass. Existing CI automatically runs command/planner/perception suites using the unchanged workflow; optional cross-checkout integrations remain local checks.
3. Manual playtests: NONE. These are automated physics/navigation checks, not a rendered gameplay, live voice, complete shared-scene or training-efficacy evaluation.

**Remaining dependencies:** Person 2 must build scene adapters for the actual opponent registry, perception/utility states and audio bus, plus autonomous goal-to-actor control. Person 1 supplies final marker/collision/navigation/utility interfaces; Person 3 supplies live accepted communication and hearing likelihoods, and owns verified video notes. Then run a shared-room manual playtest and convert those notes into baseline/reactive scenarios. PR #4's previously recorded shared-document conflicts with main remain a separate integration dependency; no merge was started.

## Person 2: new-window continuation guide

Added [bots/PERSON2_HANDOFF.md](../bots/PERSON2_HANDOFF.md), linked from the Person 2 README and lane row. It records implementation baseline 04291d8, branch/draft PR, ownership, component/API map, historical automated results, exact local reproduction commands, environment caveats, remaining dependencies and the next controller/scene integration increment. Includes a prompt to paste into a new Codex window.

Documentation-only change on person-2/bot-perception for PR #4; no runtime/schema or teammate-source changes. Actual checks for this handoff: tools/check_repo.py and git diff --check passed. Godot suites were not rerun for this documentation change; the guide labels the prior 357-check result as historical. No manual playtest performed. Next: resume from the guide and verify current teammate interfaces before implementing the owned actor controller/adapters. Existing shared-document merge conflicts remain unresolved.

## Person 2: authored-path physical movement continuation

- Branch/PR: `person-2/bot-perception`, existing draft PR #4; advances issue #2 without completing the lane. Started clean at `4e0e67e`; read all required guidance and inspected/tested the existing program before editing. Fetched Person 1 `0fd1285` and Person 3 `ff2a6d7` read-only; no teammate checkout/branch was edited or merged.
- Changed paths: `bots/motion_controller.gd`, `bots/MOTION_CONTROLLER.md`, `bots/README.md`, `bots/PERSON2_HANDOFF.md`, `validation/run_person2_tests.py`, and `tests/person2/motion_{actor,navigation,tests,integration}.gd` (four fixture/test scripts). Only Person 2's row and this note change in this shared document.
- Behavior/interfaces: privileged controller consumes pure planner output and trusted executor intents, follows static authored marker paths via actual Person 1 APIs, turns toward authored watch points, and yields autonomy to accepted commands. Physical arrival generates drained staged/completed feedback; duplicate dispatch cannot repeat the task. Cancel/expiry/death/invalid evidence/error stop movement. Unreachable/off-nav/invalid paths and ineffective progress stop safely; autonomous faults latch for explicit recovery. Missing flash mechanics produce honest failed feedback. See [motion API/consumer guide](../bots/MOTION_CONTROLLER.md). No comms.v1, observation, belief, shared fixture or project setting changed. Policy never receives physical handles or live opponent nodes.

**Automated results actually run (Godot 4.4.1 stable):**

1. Before changes: existing suites with `--person3-root ../callout-trainer-person3` passed 357 checks; synthetic command demo and docs checker passed. Initial sandbox certificate-store failure was resolved with approved outside-sandbox execution; strict error handling was preserved.
2. Final `validation/run_person2_tests.py --godot <Godot4.4.1_console> --person1-ref 0fd1285 --person3-ref ff2a6d7`: **442 checks pass**, exit 0 (174 command, 72 planner, 92 perception, 57 motion, 10 belief, 9 sensor/belief, 28 real room/actor/belief movement). Shared movement runs 149 physics ticks. A preceding version passed three consecutive synchronization runs; final added arbitration/stuck regressions pass. Default CI covers 395 checks; optional 47 cross-lane checks are local only.
3. Shared harness checks delayed report -> real belief -> changed goal -> actual CharacterBody3D movement/watch angle, one physical command override/completion, cancellation, expiry, shared health death, bot-local evidence and actual unseen scene-node perturbation. Motion doubles additionally cover invalid evidence/batches, duplicate dispatch, no progress/oscillation, nav errors and explicit recovery. Existing planner checks cover stale testimony. This is not a whole-game fairness proof.
4. Original synthetic command demo (`--demo`), `tools/check_repo.py` and `git diff --check`: pass. Python and Godot executable paths are unchanged from the guide above.

**Actual integration issue:** Person 1's builder bakes cell size/height 0.2/0.1 while its current project uses default navigation map cells 0.25/0.25. The first real integration emitted engine errors and was correctly rejected despite pass markers. The fixture now explicitly aligns only its temporary map and lets the navigation-ready physics frame finish before querying. Production alignment/readiness remains Person 1's dependency. The passing run still reports the builder's GPU mesh-readback bake warning; no engine/script errors remain. No teammate source/settings were patched.

**Manual playtests: NONE.** No rendered/shared-input/export/voice or training-efficacy result is claimed. The [motion guide](../bots/MOTION_CONTROLLER.md) supplies human playtest steps for after shared bootstrap integration.

**Next/dependencies:** Person 1 aligns production navigation and coordinates marker IDs/reachability/bootstrap. Person 2 wires controller plus trusted registry/sensor/utility/audio adapters, then remaining combat/scenario/safety behavior. Person 3 supplies live accepted quick-calls/current beliefs, visible failure reasons/hearing likelihoods and verified video notes. Human must verify report-driven movement/angle and command interruption in the shared room. Pro baseline/reactive branches await verified notes. Existing shared-document conflicts against main remain separate; no merge was started.

## Person 2: standalone visual test launcher

Added owned `scenes/bots/motion_visual_demo.gd`/`.tscn` and runner flags `--visual-demo`/`--visual-smoke`; updated the motion guide and Person 2 continuation handoff. `--visual-demo` prepares read-only teammate dependencies in a temporary project and opens a normal Godot window without requiring editor setup. It shows an overhead synthetic room, visible actor/facing/markers, status/evidence and report/swing/prepare/cue/cancel/kill/reset buttons and keyboard shortcuts. This is an isolated movement test with structured injected messages, not the shared first-person game or Person 3's UI. No schemas, shared settings or teammate source were changed.

Automated: `validation/run_person2_tests.py --godot <same4.4.1_console> --visual-smoke` passed (headless scene/action/lifecycle/physics/reset check), exit 0. Default 395-check suite, original synthetic demo, docs checker and whitespace checks passed. The known builder mesh-readback warning remains. **Manual rendering/input/playtests: none.** Exact launch command and expected manual behaviors are in [the motion guide](../bots/MOTION_CONTROLLER.md). Next: user runs that visual check and records observations; coordinated shared bootstrap/nav/utility/sensor/communication and scenario dependencies remain unchanged. Branch/PR remains Person 2 / draft #4.
## Assignment update: Person 3 owns video annotation

User-assigned: Person 3 watches and annotates videos; Person 2 converts verified notes into executable scenario JSON/baseline/reactive branches and validates them; Person 1 uses the notes for layout/markers. Updated the brief, ownership/workflow/decision docs and AGENTS.md. Annotation format and handoff: docs/VIDEO_ANNOTATION.md. No clip was selected or annotated in this update; no runtime/schema changes. Person 3 should deliver one compact clip's starting state, timeline, unknowns and communication opportunities early.

## Handoff notes

### 2026-11-14 — Person 1: Godot editor version pinned

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `docs/DECISIONS.md`, `docs/HANDOFFS.md`.
- Interface/schema changes and consumers: none yet. Version pin affects future `project.godot`, export presets and any version-specific API use; relevant to all lanes once the project exists.
- Actual checks run and results: `python tools/check_repo.py` not run locally (Python 3 unavailable on this machine); change is documentation-only with no new markdown links or fixture edits. CI docs workflow will run the check on push.
- Remaining work/dependency: Wonho2007 and sn-kurup must install the same Godot 4.4.1 stable build and confirm; install matching 4.4.1-stable export templates; confirm launch on target hardware. Pin remains a Person 1 proposal until the team confirms.
- Next integration step: create `project.godot`, the JSON-driven synthetic test room (`world/maps/test_room.json` + `world/sandbox_builder.gd`), actor stubs and a blank desktop export.

### 2026-11-14 — Person 1: synthetic test room + first-person player (stage 1)

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `project.godot`, `icon.svg`, `world/maps/test_room.json`, `world/sandbox_builder.gd`, `scenes/main.tscn`, `scenes/main.gd`, `scenes/player/player.tscn`, `scenes/player/player.gd`.
- Interface/schema changes and consumers: introduces the synthetic map data shape (meters, Y up, `[x,y,z]`, box center + full-extent size) and placeholder region IDs (`region_a`/`region_b`/`region_mid`) and spawn roles. Region IDs/graph and coordinate convention are NOT frozen — to be aligned with Persons 2/3 before freeze (see docs/CONTRACTS.md). `sandbox_builder.gd` exposes `get_spawn(role)` and `map_data`.
- Automated checks run and results: project opens in Godot 4.4.1 stable (Compatibility renderer); builder reports 8 geometry nodes, 3 regions, 3 spawns built from `test_room.json`; `python tools/check_repo.py` not run locally (Python 3 unavailable on this machine) — change is mostly code, docs edits add no new links.
- Manual playtest and results: tester confirmed in-editor playtest — room renders (floor, 4 walls, 3 cover crates), first-person movement (WASD + mouse look), wall/cover collision, walk/crouch/jump, Esc mouse capture toggle, and R restart all work. Not yet tested as an exported build.
- Remaining work/dependency: navigation bake (NavMesh) not yet implemented — separate next Person 1 step; no actors beyond the player; no weapons/damage/smoke/flash/defuse; no desktop export yet. Region IDs pending team freeze.
- Next integration step: bake navigation on the generated geometry (NavigationRegion3D + NavigationMesh), then add actor stubs and a blank desktop export.

### 2026-11-14 — Person 1: navigation bake on generated geometry

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `world/sandbox_builder.gd`, `scenes/main.gd`.
- Interface/schema changes and consumers: geometry is now generated under a `NavigationRegion3D` and the navmesh bakes from the same meshes. New builder API for Person 2: `navigation_ready` signal + `navigation_is_ready` flag (await before path queries), `query_path(from, to)` (snaps endpoints to the navmesh and returns a `PackedVector3Array`), and `get_region_center(region_id)`. Navigation only supplies paths; actor controllers (Person 2) move bodies — the builder moves nothing. Navmesh agent params (radius 0.4, height 1.8, max_climb 0.4, cell 0.2/0.1) are placeholders to tune in playtest.
- Automated checks run and results: navmesh bakes to 44 vertices / 42 polygons; a path query region_a -> region_b returns 14 points (routes around central cover). Bake is async; readiness is announced via `navigation_ready` after `bake_finished` and physics-frame sync, guarding against querying too early. `python tools/check_repo.py` still not run locally (no Python 3).
- Manual playtest and results: tester confirmed the project runs clean in Godot 4.4.1 (no errors/warnings in Output) with the room rendering as before. Navmesh overlay (Debug > Visible Navigation) not separately confirmed this pass.
- Remaining work/dependency: no actors beyond the player; no weapons/damage/smoke/flash/defuse; no desktop export yet. Region IDs and coordinate convention still pending team freeze with Persons 2/3. Navmesh must be re-baked after any map edit (the builder does this automatically on build/rebuild).
- Next integration step: add actor stubs (shared actor base for Person 2's bots) and a blank offline desktop export to prove the build pipeline early.

### 2026-11-14 — Person 1: shared actor base and health component

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (actors/ shared mechanics).
- Changed files: `actors/actor_base.gd`, `actors/actor_base.tscn`, `actors/health.gd`, `scenes/player/player.gd`.
- Interface/schema changes and consumers: new shared components for Person 2's bots. `ActorBase` (CharacterBody3D) holds the movement the player and bots share and exposes an intent API: `set_move_dir(Vector3)`, `request_jump()`, `move_toward_point(point) -> distance`, `teleport_to(marker)`, plus `move_mode` (RUN/WALK/CROUCH). `Health` component: `apply_damage(amount)`, `reset()`, signals `damaged`/`died`. `actors/actor_base.tscn` is a reusable actor (CharacterBody3D + capsule collision + visible capsule mesh + Health) for Person 2 to instance and attach behavior to. Fairness boundary preserved: the base holds and exposes NO references to other actors; bots drive it from their own observations/beliefs. `player.gd` now `extends ActorBase`, so player and bots use one movement implementation.
- Automated checks run and results: project loads with no errors/warnings in Godot 4.4.1; class_name resolution for `ActorBase`/`Health` is clean. `actors/actor_base.tscn` is not yet instanced anywhere (Person 2 owns bot scenes). `python tools/check_repo.py` still not run locally (no Python 3).
- Manual playtest and results: tester confirmed player movement, collision, walk/crouch/jump, mouse toggle and restart still work unchanged after refactoring the player onto the shared base.
- Remaining work/dependency: no weapons/damage sources yet (Health has no driver); no smoke/flash/spike/defuse; no desktop export yet. Region IDs/coordinate convention pending team freeze. Agent/collision-layer and capsule sizing are placeholders to confirm with Person 2.
- Next integration step: blank offline desktop export to prove the build pipeline on target hardware (brief §9.1).

### 2026-11-14 — Person 1: Windows desktop export verified

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (delivery/export).
- Changed files: `export_presets.cfg`, `docs/BUILD.md` (committed earlier); `export_presets.cfg` updated to disable resource modification.
- Interface/schema changes and consumers: none (build tooling only). Export preset "Windows Desktop" (x86_64 release) writes to `build/windows/` which is gitignored; exported binaries are not committed. `docs/BUILD.md` documents run/template-install/GUI+headless export commands.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally (Python 3.12.10 now installed). Export completed with only a harmless rcedit warning (icon/metadata embedding); disabled `application/modify_resources` so future exports are clean.
- Manual playtest and results: tester launched the standalone `build/windows/callout-trainer.exe` on the target machine (Windows, RTX 4070 laptop) — the room renders and movement/collision/crouch/jump/HUD/disclaimer all work offline, matching the editor. Export templates 4.4.1.stable confirmed installed.
- Remaining work/dependency: export save dialog defaulted to project root the first time; binaries were moved to `build/windows/`. Team members export to `build/windows/` per docs/BUILD.md. No gameplay beyond movement yet (no weapons/damage/smoke/flash/spike/defuse). Region IDs/coordinate convention still pending team freeze.
- Next integration step: first gameplay increment — damage/death wired to the Health component, keeping the player able to communicate after death per docs/COMMUNICATION_COACHING.md, and emitting player-permitted perception/death/entry/utility events for Person 3's grader.

### 2026-11-14 — Person 1: damage/death handling (comms-after-death preserved)

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (actors/ shared mechanics + player).
- Changed files: `actors/actor_base.gd`, `scenes/player/player.gd`, `scenes/player/player.tscn`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`.
- Interface/schema changes and consumers: `ActorBase` gains `is_alive`, a `died` signal (carries no killer/hidden truth), `apply_damage(amount)` passthrough, and connects the Health `died` signal; `teleport_to` now revives (is_alive=true + health reset) on restart. Player scene gains a `Health` child. Player death stops movement but keeps mouse-look and the input/comms channel alive, per COMMUNICATION_COACHING "retain speech/menu input after player death". `died` is the permitted death event Person 3's grader can forward.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads clean in Godot 4.4.1. No weapons yet — a temporary debug key (K) applies 35 damage to the player to test death; to be replaced by weapons.
- Manual playtest and results: tester confirmed HP drops 100->65->30->0 on K, status flips to DEAD, movement stops while mouse-look still works (can observe/report after death), and R restarts and revives to full HP. Also fixed swapped crouch/walk bindings (crouch now Ctrl, walk now Shift, matching the HUD).
- Remaining work/dependency: no weapons/damage source yet (K is a stand-in); no smoke/flash/spike/defuse; death does not yet emit a structured permitted event payload for Person 3 (only the `died` signal). Region IDs/coordinate convention still pending team freeze. Export save path defaults to project root — export to build/windows/ per docs/BUILD.md.
- Next integration step: a basic hitscan rifle (shared weapon model) that drives Health via apply_damage, keeping bots and player on the same rules.

### 2026-11-14 — Person 1: shared hitscan rifle

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (weapons/ shared mechanics).
- Changed files: `weapons/weapon.gd` (new), `scenes/player/player.gd`, `scenes/player/player.tscn`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`.
- Interface/schema changes and consumers: new shared `Weapon` (Node3D) for Person 2's bots. `fire(origin, direction, moving, shooter) -> {hit, position, collider}` does a physics raycast against the world and applies damage via the hit actor's `ActorBase.apply_damage`; `reload()`, `can_fire()`, signals `fired`/`ammo_changed`/`reload_started`/`reload_finished`. Fairness boundary preserved: fire() takes an aim origin/direction and a shooter node, never a target reference, and returns only observable hit info; bots aim it, they are not handed targets. Player fires LMB from the camera, F reloads. A dummy target actor (actor_base.tscn, Health, no AI) is spawned at the enemy marker so the rifle has something to hit — a Person 1 test stand-in, not a bot.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads and runs clean in Godot 4.4.1 after fixing a stray character and a bad weapon node path.
- Manual playtest and results: tester confirmed LMB fires and reduces the dummy target's HP (shown on HUD), ammo counts down with auto/manual (F) reload, and R resets player and target. Rifle stats are DOCUMENTED PLACEHOLDERS (30 body dmg, 2x head, 8 rps, 25 mag, 2s reload, 80 m, tuned spread) — not Valorant data. Removed the now-unused debug_damage_self (K) action.
- Remaining work/dependency: no recoil/weapon-switch/second weapon; head/body split is a crude height threshold; no muzzle/tracer visuals; damage events are not yet emitted as structured permitted events for Person 3's grader. Region IDs/coordinate convention still pending team freeze. The dummy target is a stand-in until Person 2's bots exist.
- Next integration step: smoke/flash utility primitives (brief §6.3), or wire structured permitted shot/damage/death events for Person 3's grader — coordinate ordering with the team.

### 2026-11-14 — Person 1: smoke and flash utility primitives

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (utility/ shared mechanics).
- Changed files: `utility/abilities.json`, `utility/smoke.gd`, `utility/flash.gd`, `utility/utility_system.gd` (new); `scenes/player/player.gd`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`.
- Interface/schema changes and consumers: data-driven utility definitions (`utility/abilities.json`) mapping abilities to the brief's primitives (los_blocker, blind; area_damage listed as stretch, not implemented). `UtilitySystem` spawns effects and exposes, for Person 2's perception and the shared weapon: `throw_smoke(at)`, `throw_flash(from, velocity)`, `segment_blocked_by_smoke(a, b)`, `point_in_smoke(point)`, `active_smokes()`, `active_flashes()`. `Smoke` is a timed spherical los_blocker on collision layer 5 ("smoke") with `blocks_segment`/`contains_point` tests. `Flash` is a tossed RigidBody3D projectile that arcs, bounces off world, and detonates after a delay, exposing `blind_duration_for(viewer_pos, viewer_forward, has_los)` scaled by facing/range. The shared `Weapon` gained an optional `occluder` so shots crossing smoke are blocked. Fairness boundary preserved: utility effects expose geometric queries, not policy inputs; flash/smoke occlude through the same tests perception will use, not special cases.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads and runs clean in Godot 4.4.1.
- Manual playtest and results: tester confirmed Q throws a spherical smoke that blocks shots (target HP stays up through it) and fogs the first-person view when inside; E tosses a flash projectile that arcs, bounces, detonates after a delay, and whiteouts the screen scaled by whether the player is looking at it (and blocked by smoke/geometry). Values are documented placeholders, not Valorant data.
- Remaining work/dependency: blind is applied to the PLAYER only (Person 2 applies it to bots via perception); no molly/area_damage (stretch); no utility ammo/cooldown limits yet; smoke also occludes the player's own aim-landing ray (can't stack a second smoke through the first). Region IDs/coordinate convention still pending team freeze.
- Next integration step: spike + defuse to complete the core round loop (player can finish and restart a retake), Person 1's lane.

### 2026-11-14 — Person 1: spike/defuse round loop and smoke deploy (fall-to-ground)

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/ + utility/ shared mechanics).
- Changed files: `world/spike.gd` (new), `world/sandbox_builder.gd`, `world/maps/test_room.json`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`, `utility/smoke.gd`, `utility/utility_system.gd`.
- Interface/schema changes and consumers: map data gains a `spike` block (position/planted/site_region); builder exposes `get_spike_position()`. New `Spike` (planted at start) with `detonation_time_s`/`defuse_time_s`/`defuse_radius_m` placeholders, hold-to-defuse (`defuse_step`/`stop_defuse`/`in_range`), and signals `defused`/`detonated`/`tick`. main.gd now tracks a round state (active/defused/detonated/player_down), handles hold-C defuse, shows a round HUD line, and resets on R. Smoke deploy reworked: `UtilitySystem.throw_smoke(at)` keeps the smoke where aimed if that point is on a surface, else raycasts down and the smoke falls straight at a constant slow speed to the ground; `Smoke.deploy(start_center, settle_center)` animates the fall and gates occlusion on `is_active` until settled (tests use the fixed settled center).
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads/runs clean in Godot 4.4.1.
- Manual playtest and results: tester confirmed the spike appears, the detonation timer counts down, hold-C within range fills the defuse over ~7s (resets on release) and completes to "SPIKE DEFUSED"; R resets the round. Smoke stays where aimed on a surface and falls to the ground when aimed in open air. Durations/speeds are documented placeholders, not Valorant data.
- Remaining work/dependency: single-player scaffold — player death ends the round (no teammates yet); detonation default 45s; no round-win for eliminating enemies (no enemy AI); spike has no plant step (planted at start per brief). Region IDs/coordinate convention still pending team freeze. Dummy target remains a stand-in for Person 2's bots.
- Next integration step: emit structured permitted events (shot/damage/death/utility/defuse) for Person 3's grader, per docs/COMMUNICATION_COACHING.md.

### 2026-11-14 — Person 1: privileged game-event bus for Person 3's grader

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (recording/ emitter side).
- Changed files: `recording/game_events.gd` (new), `scenes/main.gd`, `scenes/main.tscn`, `utility/utility_system.gd`.
- Interface/schema changes and consumers: new `GameEvents` bus that forwards existing gameplay signals into tick-stamped records and exposes `event_recorded(record)`, `record(type, actor_id, pos, payload)`, `get_log()`, `clear()`. Events wired: shot_fired, damage_dealt, actor_died (player), utility_deployed (smoke/flash), defuse_started/stopped, spike_defused, spike_detonated. `UtilitySystem` gained a `deployed(ability_id, thrower_id, position)` signal. **CONTRACT NOTE:** record shape `{id, tick, type, actor, position, payload}` is a PROPOSAL matching the brief's gameplay-event contract; Person 3 owns the frozen schema (docs/TEAM.md) and must freeze it together. **FAIRNESS:** this is the privileged stream (may carry truth/positions) for the recorder/grader only — it is NOT wired into bot policy or any policy input path.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads/runs clean in Godot 4.4.1.
- Manual playtest and results: tester confirmed the HUD event counter climbs with the correct `last:` type for firing (shot_fired/damage_dealt), smoke/flash (utility_deployed) and defuse (defuse_started/stopped/spike_defused), and resets on R.
- Remaining work/dependency: records are in-memory only (no JSONL persistence to user://runs/ yet — Person 3 owns the schema/format); no perception-side observation events (Person 2); death event carries no permitted-knowledge payload yet (killer/last-seen fields pending the comms schema extension in COMMUNICATION_COACHING). Region IDs/coordinate convention still pending team freeze.
- Next integration step: coordinate the frozen event/record schema with Person 3; optionally add JSONL run logging once the schema is agreed. Map overlay/region-polygon data for the debrief is also outstanding Person 1 work (brief §9.1 step 6).

### 2026-11-14 — Person 1: top-down map overlay data for the debrief

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/ map data).
- Changed files: `world/sandbox_builder.gd`.
- Interface/schema changes and consumers: new `get_map_overlay() -> Dictionary` for Person 3's debrief minimap. Returns plain serializable top-down (XZ) data: bounds, wall/cover rects ({id, x, z, w, d} with x/z = center, w/d = full X/Z extents), region rects (+ id/name), spawns (+ role), and spike (x/z). Static map layout is public (brief §6.4), so this is not privileged truth. Person 3 renders it with no 3D scene access.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally.
- Manual playtest and results: NOT separately verified in-engine this pass (the one-shot overlay dump was removed before commit). The function is a pure transformation of the already-validated map JSON (4 walls, 3 cover, 3 regions, 3 spawns, 1 spike) with no runtime dependencies; Person 3 should confirm the rendered minimap when integrating.
- Remaining work/dependency: overlay reflects the synthetic test room; it will update automatically when the source-site blockout replaces it. Region IDs/coordinate convention still pending team freeze with Persons 2/3.
- Next integration step: coordinate the frozen event/record and region-ID schema with Persons 2/3; optionally add JSONL run logging once schemas are agreed.

### 2026-11-14 — Person 1: bullet tracers and reload/restart key swap

- Branch/PR and owning lane: `person-1/weapon-tracers`; Person 1 (weapons/ + input).
- Changed files: `weapons/tracer.gd` (new), `weapons/weapon.gd`, `project.godot`, `scenes/main.gd`, `scenes/main.tscn`.
- Interface/schema changes and consumers: purely cosmetic + input. `Tracer` draws a short-lived streak from a muzzle offset to the shot's impact, spawned on the weapon's existing `fired` signal (works for any shooter). The shot stays HITSCAN — no travel time, no gameplay/fairness change. Input swap: reload is now R, restart is now F (HUD hints and round-end messages updated to match).
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads/runs clean in Godot 4.4.1.
- Manual playtest and results: tester confirmed the tracer is visible from a barrel-offset position (not screen-center), short-lived, and ends at the impact; R reloads and F restarts as swapped.
- Remaining work/dependency: tracer uses an opaque unshaded material (reliable under the Compatibility renderer); no muzzle flash/impact decal. Offsets/lifetime are tunable placeholders.
- Next integration step: unchanged — region graph/travel-times, sound events and the actor-command adapter remain the higher-value Person 1 coherence work.
