# Integration handoffs

Initial state: planning documents and synthetic examples only. No Godot project, tests, bot scenes, gameplay logs or evaluation results exist.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 (Wonho2007) | Communication contract specified; bot code not started | Delayed observations/leak fixture and command executor against comms.v1 | Person 3 interpreter/beliefs; Person 1 mechanics/markers; use fixtures |
| Person 3 | Starter implemented on person-3/comms-belief: structured report adapter, beliefs/trust, fixed-log replay, metrics primitives, synthetic records/audit; 47 isolated + 8 cross-lane assertions pass | Review proposed records with both consumers; quick-call UI and live goal integration | Person 1 regions/scene wiring; Person 2 due validated observations; full grading/debrief/evaluation pending |

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

## Person 3: independent communication/belief foundation

Branch: `person-3/comms-belief`, separate `callout-trainer-person3` worktree from `9231c7b`. See [the continuation guide](PERSON3_HANDOFF.md) for interfaces, limitations, commands and ordered next tasks. Original Person 2 work was not edited. GitHub access was unavailable; no issue was claimed and this branch is local, not pushed.

Changed paths: `comms/`, `belief/`, `grading/`, `recording/`, `tests/person3/`, `schemas/person3_records.schema.json`, `examples/person3_fake_run.json`, and Person 3 handoff documentation. Existing comms.v1 and legacy examples are unchanged. Proposed observation/decision/snapshot/run shapes need Persons 1/2 review, especially sighting and complete-coverage content. Enemy reports remain testimony and cannot identify a hidden enemy slot. Records and metrics are initial primitives, not a complete recorder/grader/UI.

Automated validation on 2026-11-14:

- `python tests/person3/run_checks.py --godot <Godot 4.4.1 console executable> --person2-root <original checkout>`: **47 isolated assertions and 8 executor integration assertions passed**, exit 0. Read-only copies of the current Person 2 files were used in a temporary project. The optional integration suite needs those files after merge or via that flag. This does not freeze uncommitted interfaces or prove gameplay.
- `python tools/check_repo.py`: passed documentation links and legacy synthetic-fixture checks.
- `python -m json.tool` on the new schema and fake run: passed JSON syntax. Draft 2020-12 meta-schema validation was not run (`jsonschema` is not installed); do not claim full schema validation.
- `git diff --check`: passed for the staged change.

Exact local executable paths and the visible Windows certificate-store environment diagnostic are documented in the continuation guide. The launcher tolerates only that diagnostic for this offline test; all script/other engine errors still fail. Tests cover early/foreign/duplicate input, malformed/nonfinite/Object values, immutable snapshots, local trust verification/expiry, movement normalization, replay ordering, entropy versus accuracy and executor report handoff.

Manual validation: not run. No playable goal-change demo, UI, smoke/flash/physics test, complete fairness gate, runtime recording or participant evaluation is claimed. Next: agree proposed records, wire one quick-call to a delayed bot belief/goal, then implement full grading/recording and debrief. Do not add optional speech/model work ahead of the debrief.
