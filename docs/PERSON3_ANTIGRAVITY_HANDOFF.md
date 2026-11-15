# Person 3 handoff — Antigravity (parallel tracks)

**Audience: an agent in Google Antigravity reading this file from the repo. Assume zero
prior knowledge.** This covers the two **self-contained** Person 3 tracks that run in
parallel with the main Kiro work. Each track has a clear input, output, and done-test. Do
not touch files outside your track. When done, report results; do not mark a check passed
that you did not run.

## Project context (minimum you need)

A **VALORANT comms coach**: a player speaks voice comms to AI teammates who hear, interpret,
and react, inside a VALORANT-like sandbox. You are helping **Person 3**. Hard rules that
apply to you: **no paid APIs, everything local/free, offline-capable; do not invent VALORANT
facts, pro positions or data; do not edit other people's files.** The heavy LLM/interpreter
work and the VOD annotation are done by the human in Kiro — **not your tracks.** You do two
contained pieces only.

The machine that runs heavy models is a capable PC with a discrete GPU (specific machine TBD).
Models and
STT should target that machine; they are portable files, so copy to other laptops later.

---

## Track D — Local speech-to-text (voice → text)

**Goal:** turn microphone audio into a transcript string, locally and free, fast enough to
use mid-round. This transcript becomes the input to the Kiro interpreter (do not build the
interpreter — just produce clean text).

**Build:**

1. Use a free/local STT engine — **whisper.cpp** or **faster-whisper** (CTranslate2).
   No cloud/paid speech APIs. Confirm the model license is free.
2. Pick a small/base English model first for latency; allow swapping to a larger one.
3. Write a small module (Python is fine; keep it under a Person 3-owned path such as
   `voice/` — create it) that: captures mic audio (push-to-talk is fine and preferred, so the
   player controls when a comm starts/ends), runs STT, and returns a transcript string plus a
   timestamp.
4. Expose it so the Kiro interpreter can call it or read its output (a function return, or
   writing the transcript to a small queue/file the interpreter polls — coordinate the exact
   hand-off shape with the human; default to "return a string from a function").

**Done-test (must actually run):**

- Speak 5–10 short VALORANT-style comms ("they're on heaven", "flash short", "I'm swinging
  B main"). Report the transcript accuracy and the end-to-end latency (speak → text) on the
  the GPU PC. Note failure cases (fast speech, slang, overlapping words).
- No network calls during transcription (verify offline).

**Do NOT:** interpret meaning, map to regions, or produce structured comms — that is the Kiro
interpreter's job. You only deliver accurate text + latency numbers.

**Files you create:** `voice/` module + a short `voice/README.md` documenting install, model
choice, how to run the done-test, and measured latency/accuracy. Keep any downloaded model
weights out of git (add to `.gitignore` if needed; large binaries do not belong in the repo).

---

## Track A (code half) — scenario JSON schema, validator, and coordinate→region helper

**Goal:** the structural/code scaffolding for turning the human's hand-annotated round notes
into a validated scenario file. **You do NOT watch the VOD or invent any positions** — the
human annotates (`annotations/<scenario_id>.md`); Person 2 authors the final
`scenarios/<scenario_id>.json`. You build the **schema + validator + a helper** that makes
that conversion safe and checkable.

**Context to read first (in the repo):**

- `world/maps/test_room.json` — Person 1's map shape: `regions` (id, name, center, size),
  `spawns` (id, role, position, facing), `spike`. Units: meters, Y up, Vector3 as [x,y,z]
  (see `docs/CONTRACTS.md`).
- `docs/VIDEO_ANNOTATION.md` — what the annotation notes contain and who owns what.
- `schemas/person3_records.schema.json`, `examples/person3_fake_run.json` — the existing
  Person 3 record/synthetic-run shapes and style to match.
- `docs/COMMANDS.md`, `schemas/comms_v1.schema.json` — the comm message contract.

**Build:**

1. `schemas/scenario.schema.json` — a JSON Schema (Draft 2020-12) for an executable scenario
   that extends Person 1's map shape with: `schema_version`, `synthetic`/source citation
   (VOD url, map, round, plant timestamp, annotator), `map` (Lotus), `side`, round context
   (time left, spike state, per-actor weapon + remaining util), per-actor `start_region`
   (a region id), and a `timeline` (ordered beats: actor, tick/relative time, action, region,
   evidence source, certainty) plus at least one reactive `branch`. Mark fields that may be
   `unknown`. Reuse region-id and tick conventions from the existing schemas.
2. `tools/validate_scenario.py` — validates a scenario file against that schema AND checks:
   every `start_region`/timeline region is a real region id (passed in or read from the map),
   spike state present, every util reference exists in `utility/abilities.json`, branch
   weights sum to 1, timeline is time-ordered. Undefined/unknown fields are allowed but
   flagged, not silently dropped. Exit nonzero on failure.
3. A **coordinate→region helper** (`tools/coords_to_region.py` or a function): given a map's
   `regions` (center + size boxes) and an [x,y,z] point, return which region id contains it
   (or none). This lets a future annotator or Person 2 translate observed positions into
   region ids consistently. Pure function, unit-tested.

**Done-test (must actually run):**

- `python tools/validate_scenario.py` against a small **synthetic** sample scenario you write
  (clearly labeled synthetic — NOT the real pro round; do not fabricate FNC/PRX data). It
  must pass a valid sample and reject malformed ones (bad region id, util that doesn't exist,
  branch weights ≠ 1, out-of-order timeline).
- `jsonschema` Draft 2020-12 meta-validation of `schemas/scenario.schema.json` passes.
  (`pip install jsonschema` in a local venv; the repo already uses a gitignored `.venv/`.)
- Unit tests for the coordinate→region helper (point inside/outside/edge of a region box).

**Do NOT:** write the real scenario file, invent Lotus regions, or invent any pro positions.
You produce the schema, the validator, and the helper. The real region ids come from Person 1
(frozen with the team) and the real round data comes from the human's annotation.

**Files you create:** `schemas/scenario.schema.json`, `tools/validate_scenario.py`,
`tools/coords_to_region.py` (+ a small tests file), and one clearly-synthetic sample scenario
for the done-test under `examples/` (e.g. `examples/scenario_sample_synthetic.json`).

---

## Rules for both tracks

- Local/free only, offline-capable, no paid APIs.
- Do not invent VALORANT facts, pro positions, region names or scenario data. Synthetic
  samples must be labeled synthetic.
- Stay in your track's files; do not edit Person 1's, Person 2's, or the human's Kiro files.
- Report real results from the done-tests; never claim a check you did not run.
- Keep large model binaries out of git.
- When finished, write a short note in your track's README with what was built, how to run
  the done-test, and the measured results, and tell the human so they can integrate.
