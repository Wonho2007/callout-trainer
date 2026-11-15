# Person 3 handoff — Kiro (main window)

**Audience: assume zero prior knowledge.** This is the work you drive yourself in Kiro,
where you supervise closely. The self-contained tracks (local speech-to-text, and the
scenario-JSON schema/validator helper) are split into `docs/PERSON3_ANTIGRAVITY_HANDOFF.md`
so you can run them in parallel. You are **Person 3**.

## 1. What the project is now

A **VALORANT comms coach**. Player controls one character first-person in a VALORANT-like
sandbox (Person 1). Bots play all other teammates/enemies. The player talks **out loud**;
**voice is the only input**. AI teammates **hear, interpret, and react** to comms. Enemies
mimic a real pro round and adapt. Teaching happens through **consequences**: bad comms get
your teammates caught out.

Committed decisions (`docs/DECISIONS.md`):

- **Voice only.** No quick-call menu for the player (the menu code stays as a deterministic
  test/fallback helper, not a player feature).
- **LLM makes the teammate's decisions, non-deterministically**, using only info the bot is
  allowed to have. No cheating from truth.
- **Grounding, NOT training.** You do not train or fine-tune a model. You run a free,
  pre-trained local model and give it the VALORANT vocabulary + a strict output schema at
  runtime. (Why not training: there is no VALORANT comms→intent dataset; the only adaptable
  sets are generic intent/slot corpora — Fluent Speech Commands, SLURP/MASSIVE — which still
  need hand-written VALORANT examples, plus GPU time, for a likely worse result. Those are
  recorded as the fallback/justification only. See `docs/DECISIONS.md`.)
- **Latest user clarification: fully trust player comms.** No credibility/history model, corroboration gate or numeric hedge-based credibility discount. Preserve explicit uncertainty as content. Align the existing hedge-weighted belief module and model prompt with this rule; wrong valid calls must still produce tactical reactions.
- **No paid API, local/free only.** LLM + speech run on a capable PC with a discrete GPU
  (specific machine TBD). Model files copy to the thinner laptops but run slower there.
- **Grading/debrief deferred.** Do not build it until the core works.
- **Reference round:** FNC vs PRX, Masters Toronto 2024 Grand Final, Lotus, final round,
  from the bomb plant. **You annotate it from the VOD.** Do not invent any pro fact.

## 2. Your lane

You own: `comms/`, `belief/`, `grading/` (later), `recording/`, `ui/`, `evaluation/`
(later), shared schemas, and `annotations/` (the VOD notes). In one line: **everything about
understanding and producing communication, the belief the teammate adopts, the LLM that
interprets and decides, and the scenario annotation.**

What already exists on your branch `person-3/comms-belief` (passed on Godot 4.4.1):

- `comms/report_adapter.gd`, `comms/quick_call.gd` — build/validate `comms.v1` messages.
- `belief/region_belief.gd` — current implementation still uses hedge-only numeric strength; **full player-comm acceptance alignment pending**;
  keeps an empty `trust: {}` in the snapshot for Person 2's planner contract.
- `belief/replay.gd`, `grading/belief_metrics.gd`, `recording/evidence_audit.gd`.
- `ui/quick_call/` — the panel (kept as fallback, not the player path).
- `tests/person3/*` — Godot assertion suites; run via `tests/person3/run_checks.py`.

This existing code becomes the **deterministic core/fallback** under the LLM. The new work
is the voice → LLM-grounded interpretation → belief/goal path, plus logging.

## 3. The capability spike — DO THIS FIRST (step zero)

Before building anything on the LLM, prove the non-negotiables are runnable on the target GPU PC.
Budget 30–60 min. This gates every time estimate.

1. Install a local LLM runtime on the GPU PC: **Ollama** (easiest) or llama.cpp / LM Studio.
2. Pull a small instruct model that fits that machine's VRAM (e.g. a 7–8B instruct model
   quantized, or smaller). Confirm the model's license is free for your use.
3. Measure: give it a fixed VALORANT-comms prompt (section 5) and time the response. You need
   responses fast enough to react in a round. Record tokens/sec and latency.
4. Pass/fail: if a usable model answers in a usable time with correct structured output on a
   few hand examples → proceed. If not → try a smaller model or simplify the schema, and tell
   the team the latency reality before committing.

A model file (e.g. GGUF) is portable: train nothing, copy the same file to the other laptops,
run with the same runtime. It just runs slower without the discrete GPU. Do the LLM work on
the GPU PC.

## 4. Annotate the reference round — the walkthrough you asked for

Owner: you (per `docs/VIDEO_ANNOTATION.md`). Notes go in `annotations/<scenario_id>.md`
(create the `annotations/` folder). Person 2 converts your verified notes into
`scenarios/<scenario_id>.json`. **Do not invent anything off-screen; mark unknowns.**

Scenario: FNC vs PRX, Masters Toronto 2024 GF, Lotus, final round, from the plant.

Step by step:

1. Open the official VOD. Find the final round. Note the **exact timestamp of the plant** —
   that is t=0 for the scenario.
2. Record the **source**: VOD URL, match/map/round, plant timestamp, your name as annotator,
   review status. Reference by URL/timestamp only; never download or commit footage.
3. At the plant instant, for **every player alive**, record: name, agent, side (atk/def),
   the **callout region** they are in (use the Lotus region names you freeze with Person 1),
   weapon, remaining utility, and visible HP. Mark anything you cannot see as `unknown`.
4. Pick the **player's takeover role** (which real player the user controls) and the compact
   area of Lotus B the sandbox needs.
5. Build a short **timeline** (plant → round end): for each actor, movement goal, angle held,
   utility thrown (what/where/when), entries, trades, defuse, deaths. Keep it coarse — key
   beats, not every frame.
6. Mark the **communication opportunities**: where a real callout, util plan, readiness call,
   correction or death report would matter. These are what the coach grades later.
7. For each fact, tag the **evidence source** (player POV / minimap / HUD) and certainty
   (observed / inferred / unknown). Spectator/minimap info is not automatically something a
   participant would know — that distinction matters for fairness.
8. Use the annotation table template in `docs/VIDEO_ANNOTATION.md`.

Deliver the **starting state + a rough timeline early** so Person 2 can start; refine later.
Keep it small; do not analyze the whole match.

## 5. The LLM interpreter + decision core (`comms/`, your main build)

This is the heart and the risky part. Keep it in Kiro where you steer it. Pieces:

### 5.1 Grounding vocabulary (free, from valorant-api.com)

- Pull Lotus callout regions, agent names, ability names, weapon names from
  [valorant-api.com](https://valorant-api.com) (free community catalog; cache locally).
- Produce a compact vocabulary object the LLM gets as context: the Lotus region IDs (frozen
  with Person 1), the agents in THIS scenario, their abilities mapped to the sandbox util
  primitives (smoke = los_blocker, flash = blind, molly = area_damage), and weapon names.

### 5.2 The interpreter: voice-text → structured comm

- Input: a transcript string from the STT track (Antigravity handoff) — build against typed
  text first so you are not blocked on the mic.
- A strict **system prompt**: "You translate a VALORANT teammate's spoken comm into this
  exact JSON schema and nothing else. Use only these regions/agents/abilities. If ambiguous,
  ask one clarification. Never output coordinates." Give 3–8 **few-shot examples** (e.g.
  "flash heaven I'm swinging" → `{kind: command, action: throw_flash, target: heaven, ...}`).
  Those hand-written examples are your "dataset"; they also seed a later fine-tune if ever
  wanted.
- Output: a `comms.v1`-shaped structured comm (reuse `comms/report_adapter.gd` /
  `comms/quick_call.gd` validation so the model's output is checked against the frozen schema;
  reject/clarify on invalid output). This keeps the LLM inside the contract.

### 5.3 The decision core: structured comm → belief/goal → teammate intent

- Feed the interpreted comm through `belief/region_belief.gd` (delayed, via Person 2's inbox)
  so the teammate's belief updates. Then the LLM (or a tight prompt over belief + own state +
  allowed signals) picks the teammate's **goal/intent** — non-deterministically — which
  Person 2's executor physically carries out.
- **Fairness is on you here:** the only things the model may see are the bot's released
  observations, its own state, its local beliefs, and the public-signal allowlist. Never pass
  it truth, enemy transforms, the scene, or spectator info. Build the prompt from copied
  values only.
- Keep the deterministic fallback (`knowledge_planner` path) as the circuit breaker: if the
  model is offline, times out, or emits an illegal intent, fall back to the scripted policy
  inside the same boundary. Required.

### 5.4 Logging — now load-bearing (`recording/`)

Because the LLM is non-deterministic, you **cannot replay to prove fairness or to grade**.
So log, every time the model interprets or decides: the exact inputs given to it (the copied
observations/belief/state/vocabulary), the full prompt, the raw model output, the parsed
structured result, and the tick. This recorded trace is what the fairness audit
(`recording/evidence_audit.gd`) and the later grader read. Write logs to `user://runs/` at
runtime; keep truth in a separate stream the model never sees.

## 6. Order of work (what to do in Kiro)

1. Read `callout_trainer_brief.md`, `AGENTS.md`, `docs/TEAM.md`, `docs/DECISIONS.md`,
   `docs/COMMANDS.md`, `docs/VIDEO_ANNOTATION.md`, this file, and the Antigravity handoff.
2. **Capability spike** (section 3) on the target GPU PC.
3. Freeze three seams with the team (section 7).
4. Annotate the round starting state + rough timeline (section 4); hand to Person 2.
5. Build the grounding vocabulary + interpreter against **typed text** (section 5.1–5.2).
6. Wire interpreter output → belief → teammate intent, with logging (5.3–5.4).
7. Swap in the STT track's transcript once the Antigravity track lands.
8. Integrate with Person 2's inbox/executor and Person 1's Lotus B once those exist.
9. (Deferred) grading: bot belief vs truth, which comms were wrong/late — only after core.

## 7. The three seams to freeze first (with the team)

Everything parallel depends on these. Write them down before parallel work starts:

1. **Scenario JSON shape** (Antigravity builds the schema/validator; Person 2 authors the
   file) — extends Person 1's map JSON with round context + timeline.
2. **Structured comm schema** — the exact JSON the interpreter emits (reuse `comms.v1`).
3. **Decision-log format** — the per-decision record (inputs, prompt, output, parsed, tick)
   that fairness/grading read. Person 2 needs this for the leak proof.

## 8. Files you will create or change

- `annotations/<scenario_id>.md` — your VOD notes (new folder).
- `comms/interpreter.gd` (or `.py` host) — the grounding prompt + model call + output
  validation. Reuse existing `comms/` validators.
- `comms/vocabulary.*` + a small cached valorant-api.com pull (cache file gitignored if large).
- `recording/decision_log.gd` — the non-determinism log described in 5.4.
- Extend `grading/` later (deferred).
- Update `docs/HANDOFFS.md` (your row + a continuation note), and `docs/DECISIONS.md` is
  already updated for the direction change by the planning pass; verify it reflects reality.
- Tests under `tests/person3/` for the interpreter (against typed text, deterministic-enough
  to assert the parse/validation even if the model varies — test the wrapper, not the model's
  creativity).

## 9. Hard rules

- Fairness: the model sees only copied delayed observations, own state, local beliefs, allowed
  public signals. Log everything it saw. No truth, no scene, no spectator info.
- No paid API; local/free only; offline-capable; model runs on the GPU PC.
- Do not invent pro facts — annotate from the VOD, mark unknowns, reference by URL/timestamp.
- Do not edit Person 1's or Person 2's files without coordinating in a PR.
- Keep the deterministic fallback working — it is the required circuit breaker.

## 10. Honest scope note

With your parallel setup (Kiro + Antigravity, the GPU PC for the LLM) this is roughly **10–14 hours
wall-clock** for a working vertical slice: one annotated scenario, voice/typed comm → grounded
interpretation → teammate reacts, local model, full logging. Grading, multiple scenarios,
enemy pro-mimicry polish and the debrief are later. The LLM-makes-decisions piece is the long
pole and does not parallelize — supervise it.
