# Final sprint — Person 2 (PC owner, engine + bots + inherited world)

**Context:** ~6 hours left, 2 people. Person 1 has left; you inherit their world/greybox/
spawning work. You have the capable PC with a GPU, so **all model-runtime work is yours.**
Person 3 owns everything that does not need the GPU or the live engine and hands it to you
drop-in ready. Direction is unchanged: **non-deterministic, grounded (not trained) local
LLM**; a deterministic policy fallback is the required circuit breaker. See `DECISIONS.md`.

**The capability spike (below) is step zero and decides scope** — run it first; its result
tells the team whether the full LLM-decides loop is viable in the time left or whether we
fall back to LLM-interprets-only. We have NOT cut non-determinism; the spike informs it.

---

## 0. Capability spike — DO THIS FIRST (30–45 min, on the PC)

Prove a free local model answers VALORANT-comms prompts with correct structured output fast
enough to use mid-round, BEFORE anything is built on it.

1. **Install Ollama** (easiest) on the PC. `winget install Ollama.Ollama` or the installer.
2. **Pull a small instruct model** that fits VRAM: start `llama3.1:8b` (the interpreter's
   default), fall back to `llama3.2:3b` or `qwen2.5:3b` if VRAM/latency is tight. Confirm the
   model licence is free to use.
3. **Measure** with the real interpreter prompt. From the repo root:
   ```
   # the interpreter builds the exact grounded prompt; this runs it against Ollama
   .venv\Scripts\python.exe -c "from comms import interpreter as I, vocabulary as V; c=I.OllamaClient('llama3.1:8b'); import time; t=time.time(); print(I.interpret('two on heaven i think', V.build_vocabulary(scenario_agents=['Omen','Raze']), c)); print('latency_s', round(time.time()-t,3))"
   ```
   Run it on 6–8 varied comms (report, flash command, swing, ambiguous → clarify, unsupported).
   There is a ready runbook + timer at `docs/CAPABILITY_SPIKE.md` and `docs/spike_measure.py`.
4. **Record** tokens/sec and end-to-end latency per call in `docs/CAPABILITY_SPIKE.md`.

**Go/no-go (report to the team):**
- Model returns correct `comms.v1`-shaped JSON on the hand examples AND median latency is
  low enough to react in a ~30–45s round (rule of thumb: interpret < ~1.5s; a decide call
  < ~2.5s) → **keep non-deterministic LLM for interpret AND decide.**
- Correct output but slow, or only small models fit → **keep LLM for interpret (the novel
  part), make the deterministic planner the primary decider**, LLM-decides becomes a labeled
  stretch. The interpreter already trips its deterministic circuit breaker automatically on
  timeout/illegal output, so this is a config choice, not a rebuild.
- Either way the deterministic fallback MUST stay wired (AGENTS.md, DECISIONS.md).

---

## 1. Your lane this sprint (reassigned)

You own, in priority order:

1. **Model runtime on the PC** — Ollama + model pulled; the capability spike; keep it running
   so Person 3's interpreter can hit `http://localhost:11434`.
2. **Greybox Lotus B** (inherited from Person 1) — build the compact B site from the 7 frozen
   region ids (see `annotations/fnc_prx_lotus_toronto2024_gf.md` §2 and the region table):
   `b_main`, `b_cubby`, `b_heaven`, `b_upper`, `b_pit`, `c_link`, `a_link`. Use the existing
   `world/sandbox_builder.gd` + a new map JSON (same shape as `world/maps/test_room.json`).
   Each region becomes a named `Area3D` with a world-space center/size. Keep it small; match
   layout and sightlines, not looks. This is the critical path — nothing integrates without it.
3. **Region Area3D bounds + registry** — give each of the 7 ids a bound so the
   coordinate→region helper (`tools/coords_to_region.py`, Antigravity Track A) and beliefs
   line up. This is the last piece of "seam #1" that Person 1 owed.
4. **Bot spawning** — spawn the player (takes over **Something, Yoru, PRX**) + the AI teammate
   (**f0rsakeN, Omen, PRX**) + the FNC retakers, from the scenario. Use your `scenes/bots/`
   and Person 1's actor components already on `main`.
5. **Scenario authoring** from Person 3's annotation — `scenarios/fnc_prx_lotus_toronto2024_gf.json`
   (your lane). The PRX hold line + ONE FNC reactive retake branch. Use the annotation's
   §4 starting state and §5 timeline; do not invent anything beyond the one authored branch
   (label branches "pro-inspired adaptation", not observed pro play).
6. **In-engine integration** — wire Person 3's interpreter output → delayed `told` observation
   → `region_belief` snapshot → your `knowledge_planner` / intent gate → executor moves the
   bot. Your executor already consumes the belief snapshot; the snapshot no longer carries
   `trust` (see trust note below).

---

## 2. Trust is fully removed — coordinate this merge

A coordinated cross-lane trust removal is pushed on branch **`person-3/drop-trust-planner`**
(off `main`). It edits YOUR files — `bots/knowledge_planner.gd` (drops `trust` from
`keys_exact`, the `is Dictionary` check, and the `for speaker in belief.trust` loop) and
`tests/person2/planner_tests.gd` (drops `"trust": {}` from two fixtures). Person 3 made these
edits with explicit owner approval and verified **all 505 Person 2 Godot checks pass** plus
the Person 3 integration suite against the edited planner.

**Open the PR** `person-3/drop-trust-planner` → `main` and review/merge it. The matching
Person 3 side (snapshot/schema drop `trust` too) is on `person-3/comms-belief` (`d69db0f`).
Both sides must land together so the belief-snapshot contract stays consistent: Person 3's
snapshot is now exactly `{bot_id, tick, enemies, evidence_ids}` — no `trust`.

---

## 3. The merge problem (Person 1 gone)

With Person 1 gone, decide which Person 1 branches land on `main`. `main` already has the
world scaffold, player, utility, nav (via PR #4 lineage). Unmerged Person 1 branches exist
(`person-1/b-site-map`, `-/molly-*`, `-/scan-orb`, `-/dash-ability`, `-/map-deeper-room`,
`-/divot-floor-hole`, `-/weapon-tracers`). Pick only what the Lotus B demo needs; do not pull
half-finished map experiments that break the build. The greybox you build (#1.2) likely
supersedes the test-room maps.

---

## 4. Contracts you consume from Person 3 (already built, stable)

- **Interpreter** `comms/interpreter.py`: `interpret(transcript, vocab, client) -> proposal`.
  Returns a `comms.v1`-shaped report/command/clarify/unsupported/empty. Trips a deterministic
  fallback on any model failure/illegal output. `OllamaClient` points at localhost.
- **Vocabulary** `comms/vocabulary.py`: `build_vocabulary(scenario_agents=[...])`. Region ids
  are FROZEN to the 7 Lotus B ids. The model may emit ONLY those ids.
- **Belief** `belief/region_belief.gd`: per-bot enemy-region beliefs, hedge-only strength,
  snapshot `{bot_id, tick, enemies, evidence_ids}`.
- **Decision log** `recording/decision_log.{py,gd}`: logs every interpret/decide call (copied
  inputs, prompt, raw output, parsed, tick) and rejects truth-leaking keys. Required because
  the LLM is non-deterministic — this log, not replay, is what the leak test reads.

---

## 5. Never cut (keep even at 6 hours)

Player-controlled shooting, smoke/flash, fair perception + reaction delay, the **leak test**
(fairness proof against the decision log), one new-situation branch, a visible fallback
reason/banner, and a **backup video** of a working run. If the live build wobbles at demo
time, the backup video is the demo.

## 6. Drop (ruthless, in this order if time is short)

Live mic/STT (type the comms instead — the interpreter is identical on typed text); molly /
2nd weapon / autonomous utility timing (keep scripted smoke/flash); multiple scenarios and
extra enemy branches (one line + one branch); grading/debrief/counterfactual (already
deferred); evaluation arms. Report only what you measured.

---

## 7. Handoff checkpoints

- **+0:30** capability spike done; non-determinism go/no-go called; trust PR merged.
- **+2:30** greybox + 7 regions + bot spawn; scenario JSON loads.
- **+4:00** a typed comm changes a teammate goal in-engine (the integration tripwire).
- **+5:00** one reactive branch + fallback banner; **backup video recorded**.
- **+6:00** freeze, rehearse (bot → scenario → trace), package offline build.
