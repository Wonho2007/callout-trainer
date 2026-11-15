# Integration handoffs

Current Person 2 state: delayed inbox and command runtime implemented, with isolated Godot tests and a synthetic actor trace. No playable sandbox, sensor physics, language interpreter or evaluation results are claimed. Historical planning notes below describe the state when written; this does not alter another lane's progress.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 (Wonho2007) | Preserved checkpoint; tested live inherited-scene sensing and atomic physical flash; 562 automated assertions pass; [current results](PERSON2_HANDOFF.md) | Delayed permitted follow-player entry sensing, then shared defuse/combat and scenario feasibility/branches; human sensing/utility playtest | Person 3 voice/model/log host, full-acceptance/correction alignment and delayed aim contract; Person 1 mechanics/nav; verified annotations |
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

### 2026-11-14 — Person 1: molly (area_damage) throwable utility

- Branch/PR and owning lane: `person-1/molly-utility`; Person 1 (utility/ shared mechanics).
- Changed files: `utility/molly.gd` (new), `utility/abilities.json`, `utility/utility_system.gd`, `scenes/player/player.gd`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`.
- Interface/schema changes and consumers: implements the brief's third generic primitive, `area_damage` (a deliberate approximation of a "deny space" tool, not a replica of any agent kit). `Molly` is a thrown RigidBody3D projectile that arcs/bounces, then on a fixed 1.5s fuse (from throw) drops to the floor beneath and ignites a flat ground zone that damages any ActorBase inside over time via the shared `apply_damage` path. `UtilitySystem.throw_molly(from, velocity)` spawns it; signals `ignited`/`expired`; emits `deployed("molly", ...)` for the event bus. New collision layer 6 "area_damage". Player throws with X. Fixed a stale HUD hint in main.gd (it still showed the pre-swap F reload/R restart); both HUD texts now read R reload / F restart / X molly.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads/runs clean in Godot 4.4.1.
- Manual playtest and results: tester confirmed X lobs an arcing projectile that bounces, ignites ~1.5s after the throw, drops its fire flat onto the floor (even when thrown at a wall), and damages the player/target standing inside until it burns out (~6s). Values are documented placeholders, not game data.
- Remaining work/dependency: both player and bots take molly damage (shared), but only the player throws it so far; no utility charges/cooldown limits; the fire disc is a flat cylinder visual (no particle fire). This third primitive is the basis for data-driven character loadouts (smoke/flash/molly bundles) discussed with the team.
- Next integration step: data-driven character/loadout system over the three primitives (original kits, not kit replicas), or the region-graph/sound/actor-command backbone.

### 2026-11-14 — Person 1: dash, blind-wave, split blind overlays, live minimap

- Branch/PR and owning lane: `person-1/dash-ability`; Person 1 (actors/ + utility/ + ui/ + input).
- Changed files: `actors/actor_base.gd`, `utility/blind_wave.gd` (new), `utility/abilities.json`, `utility/utility_system.gd`, `ui/minimap.gd` (new), `scenes/player/player.gd`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`.
- Interface/schema changes and consumers: (1) `ActorBase.dash(direction)` — shared collision-respecting impulse dash (speed 40, 0.18s, 2.5s cooldown; ~7.2m), `can_dash()`/`dash_cooldown_left()`, `dashed` signal; available to bots too. Player key V. (2) `BlindWave` — an original directional blind built from the generic `blind` primitive that travels forward and blinds through walls (ignores LOS), distinct from the thrown flash; `UtilitySystem.throw_blind_wave(from, dir)`, `active_blind_waves()`. Player key G. (3) Split blind feedback: flash = white overlay, blind wave = black overlay with +1s lingering blackout (separate timers). (4) `ui/minimap.gd` — top-down HUD minimap drawing the map overlay (cover/walls/spike), player dot + facing view cone, and enemy dots ONLY when inside the player's FOV cone with eye→torso line of sight (fair: shows the player's own perception, not hidden positions); clipped to its panel.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads/runs clean in Godot 4.4.1 (after fixing several `:=`-from-Variant inference errors during development).
- Manual playtest and results: tester confirmed V dashes (collision-respecting, cooldown), G sends a through-walls blind wave that blacks out the screen with an extra second, E flash whites out, and the minimap renders the room with a rotating view cone and shows the enemy only when actually visible.
- Remaining work/dependency: these are beyond the brief's first slice (second blind variant, dash, live minimap) and sit near the cut/polish list — trim candidates for the final demo. Minimap enemy list is currently just the dummy target; Person 2's bots would populate it. Values are documented placeholders.
- Next integration step: data-driven character/loadout system over the primitives, or the region-graph/sound/actor-command backbone.

### 2026-11-14 — Person 1: fair scan orb with decaying through-wall outline

- Branch/PR and owning lane: `person-1/scan-orb`; Person 1 (utility/ + ui/ + input).
- Changed files: `utility/scan_orb.gd` (new), `utility/recon_outline.gd` (new), `utility/abilities.json`, `utility/utility_system.gd`, `ui/minimap.gd`, `scenes/player/player.gd`, `scenes/main.gd`, `scenes/main.tscn`, `project.godot`.
- Interface/schema changes and consumers: a generic recon ability (original, not a kit replica). `ScanOrb` is a thrown projectile that, on a short fuse, scans its radius and reveals an enemy ONLY if it has clear line of sight to it from the orb (a fair sensor, same rules as perception — nothing behind cover is revealed). Reveals are LAST-KNOWN snapshots that decay (~4s): a yellow minimap mark (`UtilitySystem.recon_marks()`) and a `ReconOutline` that renders through walls (no_depth_test) and fades. `UtilitySystem.throw_scan_orb(from, velocity, targets)`. Player key T; main passes the enemy list as `scan_targets`/minimap `enemies`.
- FAIRNESS: the through-wall outline is PLAYER-ONLY visual, built from the orb's fair LOS scan, and decays. It is NOT wired into bot policy — no hidden truth reaches any bot, so the leak model is intact. The reveal is a snapshot of information the player could legitimately gather (and then call out), not a live wallhack.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads/runs clean in Godot 4.4.1.
- Manual playtest and results: tester confirmed T throws a scanning orb that reveals an in-LOS target as a decaying yellow minimap mark and a through-wall outline, both fading after a few seconds; targets the orb cannot see are not revealed.
- Remaining work/dependency: past the brief's first slice (trim candidate for the demo). Enemy list is the dummy target until Person 2's bots exist. Values are documented placeholders.
- Next integration step: data-driven character/loadout system, or the region-graph/sound/actor-command backbone.

## Person 2: main sync and updated direction review

At the user's request, merged main through `7e5e2b4` into `person-2/bot-perception` (`f00845f`, following `7484aad`). The earlier three shared-document conflicts were reconciled while preserving both lanes' records; Person 1's imported source/settings were not rewritten. The complete brief and required ownership/contracts/commands/decisions/workflow/handoff docs were reread. Main includes the first-person sandbox/mechanics, but Person 2's actual teammate is still not wired into that scene.

New direction documents were found on `origin/person-3/comms-belief` (`ce991a2`, aligned brief/decisions at `b078210`), not main: `docs/PERSON2_HANDOFF.md`, `docs/PERSON3_KIRO_HANDOFF.md`, `docs/PERSON3_ANTIGRAVITY_HANDOFF.md`. Read all three and the subsequent direction diff read-only. They specify voice-only comms, local grounded LLM teammate decisions, no trust model, deterministic fallback, deferred grading/debrief and Person 2 physical execution/perception/scenario runtime. Asked whether these unmerged documents are the intended authoritative update because main's older requirements conflict. No teammate branch was merged or source modified to resolve that product question.

Actual checks: official Godot 4.4.1, `validation/run_person2_tests.py --godot <same console> --person1-ref 7e5e2b4 --person3-ref ce991a2` passed **442 checks**, exit 0. Optional teammate sources were read-only copies; the hedge-only belief snapshot remains compatible via empty `trust: {}`. Docs checker and working-tree whitespace checks pass. Known runtime-bake performance warning remains. **Manual playtests: none this sync.** Next: confirm authoritative direction, then first-person bot spawning/physical intent integration in owned paths, with Person 1 bootstrap/marker coordination and Person 3 voice/LLM intent/log seams. Verified source notes and real region IDs remain dependencies.

## Person 2: confirmed voice/LLM direction and first-person teammate integration

The user explicitly confirmed the newer Person 2/3 handoffs at `b078210` as authoritative. Added those three direction documents and updated AGENTS/brief/README/DECISIONS/TEAM/COMMANDS to record voice-only player comms, grounded free/local LLM teammate goals, hedge-only beliefs with no trust, required deterministic fallback and grading/debrief deferred. Existing shared source/version and historical records were preserved. Source VOD/year/timestamps and real region IDs still need verification; no pro data was invented.

Owned runtime changes: `bots/intent_gate.gd`, `bots/teammate_runtime.gd`, `bots/FIRST_PERSON.md`, `scenes/bots/bot.tscn`, `scenes/bots/first_person.gd`/`.tscn`, two new Person 2 test scripts and runner options `--first-person`/`--first-person-smoke`. The scene inherits Person 1's actual first-person main and spawns the shared actor at the teammate marker. Player/world/weapon/utility/main source and root settings are unchanged. A disposable project supplies read-only Person 1 `7e5e2b4` and Person 3 `b078210` dependencies. No teammate source/branch was merged.

Proposed internal Person 3 seam: the scene emits `teammate_ready(runtime)`; runtime accepts normalized `submit_comm`, emits copied `policy_context_ready`, accepts validated `submit_intent`, and emits lifecycle/physical decision records. See [exact shapes and consumer rules](../bots/FIRST_PERSON.md). No comms.v1, observation or belief schema fields were changed. Context evidence must have been actually available when recorded; rejected raw testimony is excluded. Unknown/unreachable targets, invalid/expired model output and old-round responses cannot drive actors; deterministic fallback remains. Accepted commands override autonomous goals. Post-death comm delivery stays usable with a surviving teammate; public round completion stops motion. Full external-model fairness still requires Person 3's real prompt/output logs.

Actual automated results on official Godot 4.4.1: default 418 checks (174 command, 72 planner, 92 perception, 57 motion, 23 intent gate); optional read-only integrations 47 (10 belief, 9 sensor/belief, 28 shared motion), all pass against main `7e5e2b4` / Person 3 `b078210`; first-person smoke 21 checks pass. Total 486, exit 0. Original synthetic command demo, docs checker and whitespace checks pass. Initial temporary UID/path-check timing warnings were corrected in owned integration code; the existing runtime mesh-readback bake performance warning remains.

Manual first-person playtests: NONE. Voice/LLM end-to-end: UNAVAILABLE. Person 3's fetched branch contains plans and belief/menu helper code but no microphone/STT/interpreter/model service. The scene has no comm menu and states the voice connection is unavailable; structured test injections are confined to the automated smoke. This is an owned physical integration increment, not a completed voice coach, real model decision trace, source-derived scenario or full fairness proof.

Next/dependencies: Person 3 reviews/connects the proposed comm/goal/log seam and supplies voice/LLM capability results and verified annotations. Person 1 coordinates shared-main adoption, production navigation alignment and stable map/marker IDs. Person 2 wires the separately tested sensor kernels into actual registry/utility/audio adapters, adds remaining combat/utility/defuse intents and scenario/safety checks. Human must verify first-person movement, teammate rendering/navigation and restart, then real spoken reports/commands and model failure/post-death behavior on the chosen model machine. Launch/checklist: `bots/FIRST_PERSON.md`.

### 2026-11-14 — Person 1: greybox box-room map, brighter lighting, defuse rooting

- Branch/PR and owning lane: `person-1/b-site-map`; Person 1 (world/ map + lighting + player).
- Changed files: `world/maps/b_site.json` (new, now the default map), `world/sandbox_builder.gd`, `scenes/player/player.gd`, `scenes/main.gd`.
- Interface/schema changes and consumers: new default map `b_site.json` — a small greybox room with two corner cover boxes, a vertical entry hallway + arch, and a horizontal corridor spanning the width, fully enclosed. Built from a user-provided top-down sketch; it is a SYNTHETIC approximation, not an asset-accurate copy of any real map, and is labeled so. Builder default `map_path` now points at it (test_room.json is retained). Lighting: brighter sun + an opposite-side fill light so larger spaces read. Player gains `movement_locked` (rooted while actively defusing; mouse-look/comms stay active); main.gd sets it during a held defuse and clears it otherwise.
- Automated checks run and results: `python tools/check_repo.py` PASSES locally. Project loads/runs clean in Godot 4.4.1; map passes the builder's validation (unique IDs, in-bounds cover, clear spawns).
- Manual playtest and results: tester confirmed the player spawns in the corridor, walks corridor -> hallway -> arch -> room without falling off, and is rooted in place while defusing. Map is actively being iterated.
- Remaining work/dependency: the map is an in-progress synthetic layout, not a verified reconstruction; refine against Person 3's VOD annotation for any real-site accuracy. A validator edge case was noted: a spawn resting exactly on a surface top counts as "inside" (boundary `<=` in `_point_in_box`) — worked around by nudging spawns; relax the check later. `lower_regions` (sunken pit) is not yet rendered by the builder.
- Next integration step: continue map iteration; then the region-graph/sound/actor-command backbone for Persons 2/3.

## Person 2: follow-up teammate update sync

Main advanced during the work: merged `233e092` as `16affb7`, preserving Person 1's box-room/lighting/defuse-lock source and both appended handoff records. The owned FPS fixture now explicitly selects retained `test_room.json` and its launcher uses latest shared main `233e092` / Person 3 `57f809d`; it does not guess how the evolving `b_site.json` maps to old coverage markers.

Person 3 `57f809d` published local STT scaffolding and scenario schema/structural validator/coordinate helper. Inspected those read-only. Its voice results table is unfilled; no target-machine accuracy/latency/offline confirmation is claimed here. The grounded interpreter/local-model host/game bridge are still dependencies, so earlier no-STT notes describe only the prior `b078210` snapshot. Person 2 should consume the structural scenario helper while retaining physical reachability/LOS/baseline validation ownership. No Person 3 source, dependencies or microphone setup was changed.

Final verification after this update: default/cross-lane runner against Person 1 233e092 and Person 3 57f809d passed 465 checks; first-person smoke passed 21, total 486, both exit 0. Docs/whitespace checks pass. The known bake performance warning remains; no manual/voice/model test is claimed.

## Person 2: first-person launcher ownership fix

Reproduced the user's git-show failure as the normal Windows user: Git's dubious-ownership check rejected this sandbox-owned checkout, not a missing belief file. The owned runner now scopes safe.directory to the exact resolved checkout for each read-only Git invocation and exposes actual stderr. No global Git setting/ownership or teammate source changed. Updated bots/FIRST_PERSON.md and the owning handoff.

Automated: Godot 4.4.1 first-person smoke passed 21 checks as the normal Windows user with no manually supplied Git trust environment variables; binary Git read, textual listing and missing-ref diagnostics also passed. Docs/whitespace checks pass. Known bake performance warning remains; no manual/voice result claimed. User can rerun the same --first-person command.

## Person 2: use current Person 1 map in the first-person integration

Stayed on `person-2/bot-perception`; fetched and merged main 82434b6 as a31c649 (Person 1's deeper room/divot update). Shared source/map/settings remain identical to main. Changed only owned FPS scene/script, runner, smoke test, new scenarios/b_site_coverage.json and own guides/handoff notes. The FPS scene now loads b_site.json and adapts to room/entry/corridor; teammate spawning is authored in Person 2 scenario data because that map has no teammate marker. Actual route traverses corridor -> hallway/arch -> room. Map ID/region checks fail on incompatible configuration; no old-room coordinates are silently reused.

The launcher follows latest locally fetched origin/main and freezes/prints dependency commit IDs per run, preventing both stale fixed map snapshots and mixed versions during a concurrent fetch. It does not fetch or change shared settings at runtime. Consumer impact: Person 3's comm/model vocabulary for this scene is now room/entry/corridor, authored entry target remains entry; comms.v1 and the observation/belief shapes are unchanged. See bots/FIRST_PERSON.md.

Automated Godot 4.4.1: 465 default/cross-lane checks plus 29 FPS assertions passed (494 total), exit 0, using Person 1 82434b6 / Person 3 57f809d. Checks include actual current map/deeper-room/divot data, registered regions, new spawn, physical navigation through the hallway to room coverage, stale old-region rejection and reset. Docs/whitespace checks passed. Known mesh-readback bake warning remains. Manual: user confirmed previous FPS startup/teammate but old map; NEW-map visual/gameplay playtest remains pending. Voice/model service integration remains pending.

## Person 2: full player-comm acceptance and current work plan

User confirmed correct new-map startup and a visible teammate, then explicitly required teammates to always fully trust player comms. Updated callout_trainer_brief.md and docs/PERSON2_HANDOFF.md with the full-acceptance rule and removed obsolete trust formulas/tuning/evaluation tasks. Active AGENTS/README/decision/ownership/contract/command/consumer guides now agree. No credibility/history penalty or numeric hedge-based credibility discount is a requirement; explicit uncertainty remains content, and clarification/delay/validity/feasibility/provenance still apply. Historical handoff results are retained as history.

Refreshed Person 2 priorities: wire live sight/hearing/smoke/blind adapters into the current FPS runtime; coordinate voice/local-model comm/goal/log wiring with Person 3 in parallel; complete shared physical actions and safety handling; convert verified source notes into executable enemy/scenario branches with structural and physical validation. Person 3's current numeric hedge-weighted belief module still needs alignment with full acceptance. No runtime/schema/fixture or teammate-source change is claimed by this docs-only update.

Checks: tools/check_repo.py and git diff --check passed. Godot suites were not rerun for documentation-only changes; prior 494 checks remain historical. Manual result: user reports current map correct and teammate visible; no further gameplay/voice validation inferred. Next exact acceptance/dependencies are in docs/PERSON2_HANDOFF.md.

### 2026-11-14 — Person 1: walk-in circular divot (lower level)

- Branch/PR and owning lane: `person-1/divot-floor-hole`; Person 1 (world/ builder + map).
- Changed files: `world/sandbox_builder.gd`, `world/maps/b_site.json`.
- Interface/schema changes and consumers: `divots` map field now renders a real walk-in lower level. `_build_divot` generates a recessed flat bottom + a gentle sloped conical ramp (RAMP_RUN_FACTOR 2.5 → ~22° walkable up and down) with trimesh collision. `_build_floor` splits into four box slabs leaving a square gap for the pit, plus a solid cap across the gap at pit depth so a player cannot fall through the circle-vs-square corners. The top-right box is extended downward to seal against the pit (no air gap). Bounds min y lowered to -1 to allow the sub-floor pit/skirt.
- Automated checks run and results: `python tools/check_repo.py` PASSES. Map passes the builder's validation (build result 0).
- Manual playtest and results: tester confirmed the circle is a usable lower level — walk down and back up the slope, no fall-through, no air gap under the box; movement and smoke/flash/molly all still work.
- Remaining work/dependency: the floor gap is square while the pit is round, so the corners are covered by the solid cap rather than matched exactly (acceptable greybox). Builder currently handles a single divot's floor split; extend if multiple divots are needed. Map remains an in-progress synthetic layout.
- Next integration step: continue map iteration, then the region-graph/sound/actor-command backbone for Persons 2/3.

## Person 2 continuation checkpoint - 2026-11-14

User requested a handoff for a new Codex window. Main `487ad73` is merged locally as `28950f4` on `person-2/bot-perception`; both lane handoff records were retained. The latest divot changed navigation near the old coverage point. Moving only the owned marker to `[-1,0,3]` restored 29/29 FPS smoke checks on Godot 4.4.1 **before** live-sensor wiring.

Uncommitted, **not compiled/tested** work now includes new untracked `perception/scene_sensor.gd`, runtime sensory delivery/belief integration, adapter attachment in the inherited FPS scene, seeded scenario sensing settings, FPS context-test adjustments and runner copying. Preserve these files. No live-perception acceptance, new human playtest or voice/model result is claimed. Existing 494-check results are historical, not a result for this worktree.

The complete resume checklist, exact commands, adapter review issues, test requirements, interfaces and dependencies are in [the current Person 2 handoff](PERSON2_HANDOFF.md#continuation-checkpoint---2026-11-14-unfinished-live-sensing). First inspect/compile/test existing changes; then add an actual inherited-scene perception fixture before more intelligence. Person 3 knows the no-trust/full-acceptance rule and retains ownership of its implementation. Continue on the existing lane branch/draft PR #4; do not discard dirty work or replace Person 1's scene/map. No commit/push of this checkpoint is claimed.

## Person 2: checkpoint continuation - tested live perception and physical flash

- Branch/PR: `person-2/bot-perception`, existing draft #4. Preserved all checkpoint changes, including previously untracked `perception/scene_sensor.gd`, above main merge `28950f4` / Person 1 `487ad73`. No shared source/settings, schemas, Person 3 source or teammate checkout was edited; no merge to main.
- Changed paths: `perception/scene_sensor.gd`, `perception/README.md`, `bots/teammate_runtime.gd`, `bots/motion_controller.gd`, new `bots/flash_controller.gd`, own FPS script/config/guide, `tests/person2/{first_person_smoke,scene_perception_smoke,flash_tests}.gd`, owned runner, motion guide and own lane handoffs.
- Live adapter fixes: real horizontal velocity plus displacement for run steps; no distant off-nav listener snap; explicit blind-wave registry; sensor diagnostics retained in decision records. Shared active-smoke geometry replaces raw layer-16 collision during falling smoke. Real weapon/deployment callbacks and run sampling produce coarse path-distance audio, without source identity/position. Dispose/reset disconnects callbacks. Due supported sightings feed actual Person 3 beliefs; hearing is delivered/logged without fabricated likelihoods.
- Proposed consumer effects: `observation_delivered(observation, delivery_tick)`, decision `errors`, copied snapshot observations/own blind status/flash count. Runtime configure accepts optional own utility/flash targets/charges; old calls remain valid. Context keys, comms.v1 and observation/belief payload schemas remain unchanged. Both consumers' review details are in [FIRST_PERSON.md](../bots/FIRST_PERSON.md) and [perception/README.md](../perception/README.md). Person 1 retains shared utility/bootstrap ownership; Person 3 owns adapting voice/model/log consumers and actual prompt/output audit.
- Following the passing perception gate, implemented one scenario-authored `flash_entry` charge. On-cue staging uses the sole movement controller; valid delayed cue or now-at-launch-position creates a real shared flash projectile. Atomic reservation prevents duplicate/reentrant release; failed spawn refunds; cancel/expiry before release preserve inventory; inherited reset replenishes it. Completion means physical projectile release, not successful blindness. No model utility goals, competing interpreter or voice system was added.

Actual commands from repository root, using Python `C:/Users/Isoto/AppData/Local/Python/pythoncore-3.14-64/python.exe` and Godot `C:/Users/Isoto/Downloads/callout-godot-4.4.1/Godot_v4.4.1-stable_win64_console.exe` (`4.4.1.stable.official.49a5bc7b6`):

1. Before edits, `validation/run_person2_tests.py --godot <same console> --first-person-smoke`: 29 pass. Initial sandbox import failed on certificate-store access; approved outside-sandbox execution passed without weakening runner error handling.
2. Final `validation/run_person2_tests.py --godot <same console> --person1-ref 487ad73 --person3-ref 57f809d`: **477 pass**, exit 0 (430 owned + 47 optional). Owned breakdown: 174 command, 72 planner, 92 perception, 57 motion, 23 intent, 12 atomic flash. Read-only integrations: 10 belief, 9 sensor/belief, 28 shared motion over 149 physics ticks.
3. `validation/run_person2_tests.py --godot <same console> --perception-smoke`: **45 pass**, exit 0. Actual inherited scene/current map: delayed sight, wall collision, active/falling smoke, flash LOS/blind/recovery, through-wall wave duration, weapon/run/utility audio, quiet modes, teleport suppression, navigation detour/off-nav hearing, exact error telemetry, due belief/model evidence, copied-context isolation, equal newly generated inputs/fallback decisions under unseen live opponent perturbation, callback disposal and old pending evidence after reset.
4. `validation/run_person2_tests.py --godot <same console> --first-person-smoke`: **40 pass**, exit 0, including real flash preparation/cancellation/expiry, delayed cue/now release, actual shared projectile, physical completion, duplicate/depletion handling and inventory reset. Combined: **562 assertions**. Default CI runs 430 owned checks and synthetic demo; optional/inherited-scene checks remain local.

Known warning: shared GPU mesh-readback during runtime navigation baking. No engine/script errors in passing runs. New fixture's timer cleanup warning was investigated and fixed. `tools/check_repo.py`, `git diff --check` and the original `--demo` synthetic command trace all passed, exit 0. Explicit cross-lane diff check showed no shared source/settings/schema changes.

Manual evidence: **no new human playtest, microphone/local-model run or export test**. Prior user confirmation establishes correct-map startup/teammate visibility only. No full-game/model fairness or training benefit is claimed.

Dependencies/next: Person 3 must align full acceptance/corrections (an exploratory conflicting-report check showed earlier sight likelihoods can outweigh a new valid player report, in addition to existing hedge weights), connect voice/model/log host and provide verified notes. The passing wrong-call fixture uses a fresh belief and does not claim this gap fixed. Person 1 retains production nav cell/bootstrap alignment and shared mechanics. Next Person 2 increment: delayed permitted player-entry sensing, defuse, agreed delayed last-observed combat aim data, then physical scenario/baseline/branch checks using Person 3 helpers. No PVS/whole-region clear, defuse audio, full combat or verified pro reconstruction is completed. Human sight/hearing/smoke/flash/navigation/reset playtest remains required.
