# Integration handoffs

Initial state: planning documents and synthetic examples only. No Godot project, tests, bot scenes, gameplay logs or evaluation results exist.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 (Wonho2007) | Communication contract specified; bot code not started | Delayed observations/leak fixture and command executor against comms.v1 | Person 3 interpreter/beliefs; Person 1 mechanics/markers; use fixtures |
| Person 3 | Quick-call UI, delayed goal integration, and trust model removed on person-3/comms-belief; belief/replay/metrics/audit foundation. Godot suite passes on 4.4.1 (43+34+8+20 assertions); schema validation passes | Human UI playtest; confirm shapes with 1/2; grading/debrief/evaluation | Person 1 regions/scene wiring; Person 2 due validated observations (planner already consumes beliefs); full grading/debrief/evaluation pending |

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

## Person 3 continuation: quick-call UI and delayed goal integration

- Branch/PR and owning lane: `person-3/comms-belief`, Person 3. Local only; not pushed (git reachable here only through a bundled executable path).
- Changed files: added `comms/quick_call.gd`, `ui/quick_call/quick_call_panel.gd`, `ui/quick_call/quick_call_panel.tscn`, `ui/quick_call/README.md`, `tests/person3/quick_call_tests.gd`, `tests/person3/belief_goal_integration.gd`; edited `tests/person3/run_checks.py` to run the two new scripts (and copy Person 2's `knowledge_planner.gd`). No other lane's files, schemas, fixtures or the main scene were touched.
- Interface/schema changes and consumers: none. The quick-call emits existing `comms.v1` report/command/cue/cancel messages via `report_adapter.gd`; no schema was changed. The proposed record/observation/content shapes still need the Persons 1/2 review already flagged.
- Actual checks run and results: `python tests/person3/run_checks.py --godot <4.4.1 console> --person2-root <person-2 worktree at b3b4ddb>` passed with **47 isolated + 34 quick-call + 8 executor-integration + 20 goal-integration assertions, exit 0**, on Godot 4.4.1.stable.official.49a5bc7b6. `python tools/check_repo.py` passed; `python -m json.tool` on all JSON passed; Draft 2020-12 meta-schema validation of both schemas, conformance of the fake run, and conformance of all six quick-call message shapes to `comms.v1` all passed using a locally installed `jsonschema` (in an ignored `.venv/`); independent Python re-derivation reproduced every belief/trust number including the logs-to-0.8 goal switch; `git diff --check` passed. The engine run caught and fixed one bug: the quick-call `reference()` method name collided with `RefCounted.reference()` and was renamed `make_reference()`. No manual UI playtest was run.
- Remaining work/dependency: a human playtest of the panel (rendering/input/layout are unverified); the full shared fairness fixture beyond the membership/time audit (Person 2 integration); real merge with Persons 1/2. Person 2's `knowledge_planner.gd` already consumes the belief snapshot, so the goal path is proven from both sides.
- Next integration step: on merge, re-run the suite against the merged tree, then host the panel in a scene and playtest. Local tooling used this session: Godot at `C:\Users\Siddh\tools\godot\Godot_v4.4.1-stable_win64_console.exe` and a Person 2 worktree at `C:\Users\Siddh\projects\callout-trainer-person2`. (This increment was later pushed to origin; the "local only" note above was true at the time of writing.)

## Person 3: trust model removed

- Branch/PR and owning lane: `person-3/comms-belief`, Person 3.
- Changed files: `belief/region_belief.gd` (removed trust state, η rates, verification window, confirmation/refutation/expiry; hedge is now the only strength knob), `tests/person3/run_tests.gd`, `tests/person3/executor_integration.gd`, `tests/person3/belief_goal_integration.gd` (updated expectations), `docs/DECISIONS.md` and `docs/PERSON3_HANDOFF.md`. No other lane's files were edited.
- Interface/schema changes and consumers: the belief snapshot still contains all contract keys. The `trust` key is retained as an always-empty dict so Person 2's planner `keys_exact` check keeps passing; nothing populates it. Person 2 may drop `trust` from `knowledge_planner.gd` validation in a coordinated change. A `sure` report now yields belief ≈ 0.933 on the called region (was 0.8 under τ=0.7); this still clears the planner's 0.55 threat threshold, so goal switching is unaffected. Decision recorded in DECISIONS.md; the symmetric/asymmetric trust evaluation arm (brief §7.3) is dropped.
- Actual checks run and results: `python tests/person3/run_checks.py --godot <4.4.1 console> --person2-root <person-2 worktree at b3b4ddb>` passed with **43 isolated + 34 quick-call + 8 executor-integration + 20 goal-integration assertions, exit 0**, on Godot 4.4.1. Separately, Person 2's own `planner_belief_integration.gd` was run against the modified belief model in a disposable project and passed (10/10). `python tools/check_repo.py` passed.
- Remaining work/dependency: Person 2's optional cleanup of the vestigial `trust` field; the same human UI playtest and full fairness fixture still owed from the prior increment.
- Next integration step: coordinate the empty-`trust` field with Person 2 at merge; continue to grading metrics (increment 2).

## Person 3: Track D voice STT merged + grounded interpreter/decision log

- Branch/PR and owning lane: `person-3/comms-belief`, Person 3. Pushed to origin.
- Changed files: merged `origin/person-3/voice-track` (fast-forward) bringing `voice/stt.py`, `voice/push_to_talk.py`, `voice/__init__.py`, `voice/README.md` (offline faster-whisper `small.en`, int8, peak-normalize, tactical-callout `initial_prompt`, temperature 0, Silero VAD, repetition penalty). Added `comms/vocabulary.py`, `comms/fetch_vocabulary.py`, `comms/vocabulary_cache.json`, `comms/interpreter.py`, `comms/README.md`, `recording/decision_log.py`, `recording/decision_log.gd`, `docs/CAPABILITY_SPIKE.md`, `docs/spike_measure.py`, `tests/person3/test_interpreter.py`, `tests/person3/test_decision_log.py`. No other lane's files touched; the `annotations/` VOD file is the human's lane (left as-is).
- Interface/schema changes and consumers: no schema change. The interpreter emits a `comms.v1` **proposal** (intent/target/timing for a command; region/count/hedge for a report); a trusted adapter still stamps `message_id`/`speaker_id`/`recipient_id`/`issued_tick`/`expires_tick` (docs/COMMANDS.md). `recording/decision_log.gd` records carry `bot_id`/`tick`/`evidence_ids`, consumable by `recording/evidence_audit.gd`. **Pending Person 1:** frozen Lotus B region ids and entry/flash marker ids — `comms/vocabulary.REGION_IDS` is a labeled placeholder (`REGIONS_FROZEN=False`); no pro position invented.
- Actual checks run and results: `python -m pytest tests/ -q` → **52 passed** (interpreter wrapper parse/validation, circuit-breaker fallback on offline/junk/illegal output, clarify/unsupported, never-infer-1-from-"someone"; decision-log shape + truth-leak rejection; 25 coords_to_region). Track A re-verified: `validate_scenario.py` exit 0 on the synthetic sample, exit 1 on mutated variants; scenario schema is valid Draft 2020-12. `voice.stt` imports and `transcribe()` is callable; STT deps installed except `torch` (CPU fallback automatic). End-to-end interpreter smoke over the real cache produces correct proposals. **Not run:** real local-LLM latency/accuracy (needs the GPU PC — see docs/CAPABILITY_SPIKE.md, table unfilled); mic→text latency/accuracy on the GPU PC; any Godot runtime/playtest.
- Remaining work/dependency: Step 3 capability spike on the GPU PC (runbook ready); Step 4 VOD annotation (human, other window); freeze region/marker ids with Person 1 then swap placeholders; wire interpreter → `belief/region_belief.gd` via Person 2's delayed inbox and pick teammate goal/intent with full decision logging (Step 6 decision core); swap typed text for `voice.stt.transcribe()`.
- Next integration step: run the capability spike on the GPU PC and fill the table; coordinate frozen Lotus B region/marker ids with Person 1; then build the comm→belief→goal decision core against Person 2's inbox.
