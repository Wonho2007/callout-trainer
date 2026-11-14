# Person 3 starter handoff

Branch: `person-3/comms-belief`, based on `9231c7b`. Worktree: `callout-trainer-person3`, adjacent to the original checkout. The original `person-2/bot-perception` worktree and its uncommitted files were left alone. No Person 3 GitHub identity has been assigned. GitHub/network access was unavailable, so issues could not be inspected or claimed and this branch has not been pushed.

This is the first independent lane increment, not completion of Person 3's full assignment. It prepares a world-independent communication/belief path while Persons 1/2 build gameplay. Read the brief, AGENTS.md and shared contracts before continuing.

## Implemented paths

| Path | Purpose |
|---|---|
| [report_adapter.gd](../comms/report_adapter.gd) | Creates/validates the report subset of comms.v1; produces a copied delayed told envelope. No actor actions, transcription or interpretation. |
| [region_belief.gd](../belief/region_belief.gd) | Per-bot, per-enemy probabilities, explicit movement matrix, delayed evidence, idempotent reports, local trust and verification expiry. |
| [replay.gd](../belief/replay.gd) | Availability-ordered deterministic observation replay, with optional explicit movement steps. Suitable foundation for belief-only counterfactuals. |
| [belief_metrics.gd](../grading/belief_metrics.gd) | Entropy in bits and evaluator-only Brier score. Unknown truth returns null. |
| [evidence_audit.gd](../recording/evidence_audit.gd) | Rejects duplicate, missing, foreign and future evidence in an offline log. This is only the membership/time part of the fairness gate. |
| [records schema](../schemas/person3_records.schema.json) | Proposed observation/decision/snapshot/synthetic-run shapes. Existing shared contracts are not frozen or replaced. |
| [fake run](../examples/person3_fake_run.json) | Explicitly synthetic testimony, later sighting and illustrative decision. The decision is fixture data, not generated gameplay behavior. |
| [tests](../tests/person3/run_tests.gd) | Actual Godot assertions covering delayed input, copying, malformed input, deduplication, trust/expiry, prediction, audit, metrics and replay. |
| [quick_call.gd](../comms/quick_call.gd) | Mandatory deterministic quick-call model. Builds the menu and validated comms.v1 report/command/cue/cancel messages from a fixed scenario vocabulary. No speech, scene, world or invented coordinates. |
| [quick-call panel](../ui/quick_call/quick_call_panel.gd) | Thin Control view: renders the menu, emits the chosen message and shows lifecycle acknowledgments. Does not edit the main scene. See [the UI README](../ui/quick_call/README.md). |
| [quick-call tests](../tests/person3/quick_call_tests.gd) | Godot assertions for the quick-call model: menu, message building, rejection of unknown region/hedge/target/timing, acknowledgment mapping. |
| [goal integration](../tests/person3/belief_goal_integration.gd) | Optional Person 3 harness proving a delayed quick-call changes a bot goal through Person 2's real executor/inbox/planner (copied read-only). |

## Integration for Persons 1 and 2

No existing comms.v1 schema, root project settings, scene, legacy fixture or Person 2 implementation was changed. Both consumers must review the proposed records before adoption. `speaker_id` matches the locally observed Person 2 inbox envelope; the old illustrative fixture uses `speaker` and is deliberately unchanged.

Person 1 supplies stable region IDs and a configured one-step movement matrix from travel times. The model does not infer tick rate or physics timing. Initial priors are uniform. The three region IDs in the fake run are synthetic and do not select a real map.

Person 2 supplies only due, bot-local copied observations. Envelope fields are exactly `id, bot_id, event_tick, available_tick, source, speaker_id, content`. Call `apply(observation, current_tick)` before planning, then query `snapshot()`. Copies are returned. Do not hand the model a scene, node, private archive or world object. Example wiring after both lanes are merged:

```gdscript
const Belief = preload("res://belief/region_belief.gd")
const Reports = preload("res://comms/report_adapter.gd")
var belief = Belief.new("ally_1", ["entry", "site", "upper"], ["enemy_1"])
var message = Reports.make_report("call_1", "player", "ally_1", 120, 220, "upper")
var observation = Reports.told_observation(message, "obs_call_1", 138)
# Queue observation in Person 2's inbox/executor. It must not reach beliefs early.
# After executor validation and delayed release at tick 138:
var result = belief.apply(observation, 138)
var local_beliefs = belief.snapshot()
```

Route reports through executor recipient/alive/catalog validation first. This model validates data and local testimony, not actor feasibility. Do not convert executor `reports` into fresh observations or reapply the message: retain the original evidence ID. The executor's result means processed, not verified. Commands/cues/cancels stay with Person 2. Unknown/heard content currently returns an explicit unsupported result; the caller can retain it for the other consumers.

Proposed sighting content: `{type: "enemy_seen", enemy_id, region_id}`. Proposed negative evidence: `{type: "region_clear", region_id, coverage: "complete"}`. Person 2 must establish full current coverage, including smoke and partial cover, before producing it. These content names require review; they are not silently frozen by the new schema.

Trust defaults (placeholders): 0.7 initial, +0.1 confirmation rate, -0.4 refutation rate, 60-tick verification window. Positive same-region local evidence can confirm within the window. A later sighting elsewhere or later clearance does not prove an earlier report false. Only simultaneous complete coverage refutes testimony in this conservative first adapter. Verification arriving after expiry stays unresolved. A symmetric control is configurable by setting equal rates.

Reports have no enemy identity: this starter applies a soft likelihood to exchangeable enemy slots, retains count without inventing slot identity, and does not model joint occupancy/count constraints. Count-aware association and sound likelihoods remain work. Hedge scales testimony strength independently of trust; no parser confidence is invented. Prediction requires an explicit normalized matrix and advancing tick; same-tick evidence is allowed after prediction.

Replay accepts only the bot's observation list and static configuration. Private truth is separate in the fake archive and is used only by evaluator metrics. There is no private archive reader on the policy path. Runtime JSONL recording is not implemented; future logs belong in `user://runs/`.

## Reproduce checks

Python 3.10+ and a Godot 4 stable executable are required. The test wrapper creates a temporary minimal project; it never edits Person 1's project or pins the team editor version.

```powershell
python tests/person3/run_checks.py --godot "C:\path\to\Godot_console.exe"
# Optional: test against Person 2 files, copied read-only to the temporary project.
python tests/person3/run_checks.py --godot "C:\path\to\Godot_console.exe" --person2-root "..\callout-trainer"
python tools/check_repo.py
git diff --check
```

The isolated suite now runs `run_tests.gd` and `quick_call_tests.gd`. With
`--person2-root` it also runs `executor_integration.gd` and the new
`belief_goal_integration.gd`; the wrapper copies Person 2's `command_executor.gd`,
`observation_inbox.gd`, `knowledge_planner.gd`, `comms_validator.gd`,
`plain_data.gd` and `comms_v1.schema.json` read-only.

The local Python app-execution alias was inaccessible; checks were run with
`C:\Users\Isoto\AppData\Local\Python\pythoncore-3.14-64\python.exe`. Godot
executable: `C:\Users\Isoto\Downloads\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe`,
reporting `4.4.1.stable.official.49a5bc7b6`. Results are recorded in HANDOFFS.md
after verification. The wrapper displays and tolerates only the exact Windows
certificate-store diagnostic seen in this sandbox; all script errors, other engine
errors, failed assertions, missing pass marker and nonzero exits fail. No network
calls occur in the suite.

No manual game/UI playtest has run. Membership/time assertions do not establish the complete fairness gate: policy dependency checks, hidden-state perturbation and actual smoke/flash/physics tests remain Person 2 integration work. JSON schemas describe shape; temporal relationships and normalized probabilities require runtime checks.

Actual results: 47 isolated assertions plus 8 optional executor integration assertions passed on Godot 4.4.1, exit 0. Documentation checks and JSON syntax checks passed. Draft 2020-12 meta-schema validation was unavailable because `jsonschema` is not installed. The integration test uses the current local Person 2 files; it is not a frozen dependency. Equal availability times sort by event tick and then observation ID to match that inbox. Reviewing Person 2's current uncommitted guide also showed Person 1 has proposed Godot 4.4.1; whole-team version/export confirmation remains pending.

### 2026-11-14 continuation: quick-call UI and delayed goal integration

Added the mandatory quick-call model and Control, their isolated test, and a Person 3
goal-integration harness. New files: `comms/quick_call.gd`, `ui/quick_call/quick_call_panel.gd`,
`ui/quick_call/quick_call_panel.tscn`, `ui/quick_call/README.md`,
`tests/person3/quick_call_tests.gd`, `tests/person3/belief_goal_integration.gd`; wired the
two new scripts into `tests/person3/run_checks.py`. No existing Person 1/2/3 file, schema,
fixture or main scene was edited. The quick-call emits only validated `comms.v1` messages
over the existing `report_adapter.gd`; it never invents regions, markers or coordinates.

Automated checks run this session, on a machine **without a Godot executable**:

- `python tools/check_repo.py`: passed (documentation links and synthetic fixture).
- `python -m json.tool` on all four JSON files: passed (syntax).
- **Draft 2020-12 meta-schema validation, now actually run** via a local `jsonschema` 4.26.0
  (installed in an ignored `.venv/`, not committed): `schemas/person3_records.schema.json`
  and `schemas/comms_v1.schema.json` are valid Draft 2020-12 schemas; `examples/person3_fake_run.json`
  conforms to the records schema; and all six quick-call message shapes (report with/without
  count, swing, flash, cue, cancel) conform to the frozen `comms.v1` oneOf. This closes the
  earlier "meta-schema validation unavailable" gap for these artifacts.
- Independent re-derivation of the belief/trust formulas (Python) reproduces every numeric
  assertion in the GDScript suite (report-to-0.8, trust 0.73/0.42/0.63, hedge < 0.8) and the
  new integration claim (logs to 0.8, above the 0.55 threat threshold, fresh and reachable,
  so the planner switches to `logs_cover`).
- Static checks: every `preload` path resolves (Person 2's executor/planner resolve via the
  wrapper's read-only copy at test time), tab indentation and headers match the lane style,
  and `run_checks.py` parses.

**Not run this session (honest):** the Godot assertion suite could not execute because no
Godot 4 stable executable is installed on this machine. The existing 47+8 assertions and the
new `quick_call_tests.gd` and `belief_goal_integration.gd` still need a Godot run by a
teammate with the pinned editor (commands above). No manual UI playtest was run: rendering,
mouse/keyboard input and on-screen layout of the quick-call panel are unverified and remain a
required human playtest. `git diff --check` was not run in this session's shell (git is only
reachable through a bundled path here); run it before the PR.

## Next small increments, in order

1. **Mostly done, pending verification.** The mandatory quick-call Control and
   lifecycle acknowledgments are implemented (`ui/quick_call/`), and one delayed
   quick-call is integrated into a bot goal through Person 2's real executor and
   planner (`tests/person3/belief_goal_integration.gd`). Remaining before this is
   closed: run the Godot suite with the pinned editor, do the human UI playtest,
   confirm the envelope/content/query shapes with Persons 1/2, and run the full
   shared fairness fixture (not just the membership/time audit). Pin the editor
   version with Person 1. Note: Person 2's `knowledge_planner.gd` already consumes
   the belief snapshot and ships its own read-only cross-lane test, so the goal path
   is now proven from both sides against copies; it still needs a real merge and a
   combined Godot run.
2. Add player-sighting intervals and time-indexed truth contracts, then precision/recall/median latency and correct-versus-wrong callout metrics. Undefined denominators must return unavailable. Save real runtime observations/decisions and truth separately.
3. Build the scrubbable truth-versus-belief debrief and visible belief-only counterfactual using fixed observations. Get map outlines from Person 1. This replay helper does not yet choose the best omitted call or render a comparison.
4. Add silent/chatty/budgeted outputs, repeated-report suppression and channel busy/rate limits from bot-local evidence; keep combat identical. Build the noisy-callout pilot, VOD-only sheet and unseen pre/post protocol. No human or pilot results have been collected.
5. Typed natural-language interpretation/clarification, then optional speech after the debrief works. Current structured reports and the quick-call menu are a fallback foundation, not the requested flexible-language interpreter.

Do not claim the full lane, playable integration, debrief, complete grading, evaluation arms, speech or full fairness gate complete from these isolated checks.
