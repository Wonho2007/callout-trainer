# Integration handoffs

Current Person 2 state: delayed inbox and command runtime implemented, with isolated Godot tests and a synthetic actor trace. No playable sandbox, sensor physics, language interpreter or evaluation results are claimed. Historical planning notes below describe the state when written; this does not alter another lane's progress.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 (Wonho2007) | Command runtime, knowledge planner and physics/nav perception kernel tested; real-sighting-to-Person-3-belief-to-goal integration passes | Wire actual scene registry/utility/sound adapters and autonomous actor control; convert verified annotations to baseline/branches | Person 1 actor/nav/utility/event interfaces; Person 3 live messages/beliefs, hearing likelihoods and verified notes |
| Person 3 | Not started | Freeze schemas; fake run and evidence/time checks | Shared contracts; use synthetic fixture |

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
