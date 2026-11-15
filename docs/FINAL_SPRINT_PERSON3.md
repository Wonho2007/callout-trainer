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

1. **Interpreter → belief → intent glue (headless + live-ready).** The pieces exist; wire them
   end to end as a pure path, testable without the GPU or engine, and shaped so a **live mic
   transcript** drops in unchanged on Person 2's PC:
   `transcript` → `comms.interpreter.interpret()` → `comms.v1` message → a `told` observation
   (reaction delay applied) → `belief/region_belief.gd` update → snapshot → the shape Person
   2's intent gate consumes. The transcript source is interchangeable: a typed string for your
   headless tests, the `voice/` STT output on the PC. Use a stub model client (Echo/Broken) so
   it runs offline; the real `OllamaClient` drops in on the PC. Test every branch: valid
   report, clarify, unsupported, model-illegal → deterministic fallback. **Define the exact
   transcript hand-off shape with Person 2 so the live mic plugs straight in** (default: a
   function that takes a transcript string + timestamp and returns the proposal).

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

## 3. Live speech-to-text (central — Person 2 runs it on the PC, you own the hand-off)

The player speaks comms out loud — **voice is the only player input, so live mic/STT is core
to the product and is NOT dropped.** The `voice/` module (Antigravity Track D) is on
`person-3/voice-track`, isolated in the `callout-trainer-voice` worktree. It needs the PC's
mic + GPU, so Person 2 runs and verifies it on the PC. **Your job is to make the transcript
plug straight into the interpreter glue (§1):** define the hand-off shape (transcript string +
timestamp → proposal), test it headless with typed strings, and confirm with Person 2 that
the `voice/` output matches that shape so the live mic connects with no rework. The demo chain
is **player speaks → STT text → grounded LLM interprets → belief updates → teammate reacts.**

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

**Never cut:** **live mic / speech-to-text** (voice is the only player input — central to the
product), the leak test (fairness proof against the decision log), the deterministic fallback
path, a visible fallback reason, honest labeling, and helping produce the backup video.
**Drop if short:** grading/debrief/counterfactual (deferred), evaluation arms, multiple
scenarios. Report only what was measured. **Do NOT drop live mic/STT.**

---

## 6. Handoff checkpoints (mirror Person 2's)

- **+0:30** after the capability spike, confirm with Person 2 whether the glue targets
  LLM-decides (full non-determinism) or LLM-interprets-only + deterministic decide. The glue
  supports both; it is a client/config choice, not a rebuild.
- **+2:30** interpreter→belief→intent glue + decision-log wiring done and green headless;
  transcript hand-off shape confirmed with Person 2 so the live mic plugs in.
- **+4:00** leak-test/fairness audit green on a sample decision log; ready for the real run.
- **+5:00** demo script written; assist the backup video (a real spoken-comm run if possible).
- **+6:00** rehearse the trace narrative; package.
