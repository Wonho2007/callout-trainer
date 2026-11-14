# Integration handoffs

Current Person 2 state: delayed inbox and command runtime implemented, with isolated Godot tests and a synthetic actor trace. No playable sandbox, sensor physics, language interpreter or evaluation results are claimed. Historical planning notes below describe the state when written; this does not alter another lane's progress.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 (Wonho2007) | Delayed inbox, leak fixture, swing/flash command runtime and fake actor demo implemented | Connect real actor/perception and belief adapters; then add baseline scripts | Person 3 interpreter/beliefs; Person 1 navigation/mechanics/markers |
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
