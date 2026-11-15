# Final sprint — Person 3 (no GPU/engine: glue, fairness, demo)

**Context:** ~6 hours left, 2 people. Person 1 left; Person 2 has the PC and owns the model
runtime, greybox, spawning, scenario authoring, and in-engine integration. You have **no GPU
and no live engine**, so your job is to make every non-GPU piece drop-in ready so Person 2's
PC time is spent only on what truly needs it. Direction is unchanged: **non-deterministic,
grounded (not trained) local LLM**, deterministic fallback as the required circuit breaker.

**You do NOT run the model or the engine.** You build and test headless against typed text and
fixtures, and hand Person 2 code that works the moment the model/engine are present.

---

## 1. Your lane this sprint (priority order)

1. **Interpreter → belief → intent glue (headless).** The pieces exist; wire them end to end
   as a pure function/path, testable without the GPU or engine:
   `transcript` → `comms.interpreter.interpret()` → `comms.v1` message → a `told` observation
   (reaction delay applied) → `belief/region_belief.gd` update → snapshot → the shape Person
   2's intent gate consumes. Use a stub model client (Echo/Broken) so it runs offline; the
   real `OllamaClient` drops in on Person 2's PC unchanged. Test every branch: valid report,
   clarify, unsupported, model-illegal → deterministic fallback.

2. **Decision-log wiring (the fairness spine).** Because the LLM is non-deterministic, the
   recorded decision log — not replay — proves fairness. Make sure every interpret/decide call
   logs: copied inputs (observations, own state, local beliefs, public-signal allowlist,
   vocabulary), the exact prompt, the raw model output, the parsed result, the source
   (model/deterministic_fallback/deterministic), and the tick. `recording/decision_log.py`
   already rejects truth-leaking keys; confirm the glue in #1 calls it on every path.

3. **The leak test / fairness audit (never-cut; pure logic, no engine).** Extend
   `recording/evidence_audit.gd` / write a headless check that, over a run's decision log,
   asserts: (a) every evidence id a decision used existed and was available by that tick,
   (b) no forbidden/truth key ever appears in logged inputs, (c) identical allowed inputs
   produce the same *allowed set* even if unseen enemies move (perturbation). A grep is not a
   proof — check against the recorded log. This is the pitch's integrity claim.

4. **Scenario notes for Person 2.** Your annotation is done and pushed
   (`annotations/fnc_prx_lotus_toronto2024_gf.md`). If Person 2 asks for clarification while
   authoring `scenarios/…json`, answer from the VOD facts only; do not invent. The player
   takes over **Something (Yoru, PRX)**; the comms teammate is **f0rsakeN (Omen, PRX)**; the
   4 FNC are the retake line + one authored branch.

5. **Demo + backup narrative.** Write the demo script (bot → scenario → behavior trace) and
   the honesty labeling: "pro-inspired adaptation" on branches, "grounded not trained" on the
   model, no transfer/win-rate claims. Help Person 2 record the backup video.

---

## 2. What is already done (don't rebuild)

- **Annotation** — full FNC vs PRX Lotus B round, committed + pushed on `comms-belief`.
- **Interpreter + vocabulary** — `comms/interpreter.py`, `comms/vocabulary.py`; region ids
  FROZEN to the 7 Lotus B ids; deterministic circuit breaker built in; 27 py tests pass.
- **Decision log** — `recording/decision_log.{py,gd}` with truth-leak rejection.
- **Belief model** — `belief/region_belief.gd`, hedge-only, snapshot has NO `trust`.
- **Trust fully removed** — both sides pushed (`comms-belief` + `person-3/drop-trust-planner`).

---

## 3. STT / voice (hand to Person 2; likely dropped for the demo)

The `voice/` module (Antigravity Track D) is on `person-3/voice-track`, isolated in its own
worktree. It needs the PC + a mic to measure latency. **For the 6-hour demo, type the comms**
— the interpreter is identical on typed text, so STT is a stretch, not a dependency. If time
remains after integration, Person 2 runs the `voice/` done-test on the PC and we wire the
transcript into the glue from #1. Do not block the demo on the mic.

---

## 4. Interfaces you expose to Person 2

Keep these stable so Person 2 can integrate without waiting on you:

- `comms.interpreter.interpret(transcript, vocab, client=None, on_log=...)` → proposal dict.
- `comms.vocabulary.build_vocabulary(scenario_agents=[...])` → grounded vocab (7 frozen ids).
- `comms.report_adapter` / `comms.quick_call` → build/validate `comms.v1` messages (GDScript).
- `belief/region_belief.gd` → `apply(observation, tick)`, `predict()`, `snapshot()`
  (`{bot_id, tick, enemies, evidence_ids}`).
- `recording/decision_log` → `make_record(...)` / `DecisionLog.append/log_interpret`.

---

## 5. Never cut / Drop

**Never cut:** the leak test (fairness proof against the decision log), the deterministic
fallback path, a visible fallback reason, honest labeling, and helping produce the backup
video. **Drop if short:** live mic/STT (type comms), grading/debrief/counterfactual (deferred),
evaluation arms, multiple scenarios. Report only what was measured.

---

## 6. Handoff checkpoints (mirror Person 2's)

- **+0:30** after the capability spike, confirm with Person 2 whether the glue targets
  LLM-decides (full non-determinism) or LLM-interprets-only + deterministic decide. The glue
  supports both; it is a client/config choice, not a rebuild.
- **+2:30** interpreter→belief→intent glue + decision-log wiring done and green headless.
- **+4:00** leak-test/fairness audit green on a sample decision log; ready for the real run.
- **+5:00** demo script written; assist the backup video.
- **+6:00** rehearse the trace narrative; package.
