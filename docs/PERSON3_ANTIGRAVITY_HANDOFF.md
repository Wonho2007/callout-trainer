# Person 3 Handoff — Antigravity to Kiro Transition

> **Audience: Kiro agent taking over Person 3's full lane.**
> Antigravity previously handled the two parallel sub-tracks (Track A code half and Track D local STT).
> This document records what was built, where it lives, passing tests, and how to seamlessly take over and finish the integration.

---

## 1. Repository & Branch Setup

Two worktrees share the same underlying `.git` repository:

| Folder | Branch | Owned Contents |
|---|---|---|
| `C:\Users\Siddh\projects\callout-trainer` | `person-3/comms-belief` | Main Person 3 lane: `comms/`, `belief/`, `annotations/`, `schemas/`, `tools/` |
| `C:\Users\Siddh\projects\callout-trainer-voice` | `person-3/voice-track` | Track D: `voice/` (isolated worktree to prevent uncommitted file collisions) |

Git executable (bundled with GitHub Desktop):
`C:\Users\Siddh\AppData\Local\GitHubDesktop\app-3.6.5\resources\app\git\cmd\git.exe`

Python venv (shared across worktrees):
`C:\Users\Siddh\projects\callout-trainer\.venv`

---

## 2. What Was Built & Verified

### Track A (Code Half) — Scenario Schema, Validator & Coord Helper
*Already committed and pushed to `person-3/comms-belief` (commit `57f809d`).*

1. **`schemas/scenario.schema.json`**:
   - JSON Schema (Draft 2020-12) for executable scenario definitions (`schema_version: scenario.v1`).
   - Validated against Draft 2020-12 meta-schema (`Draft202012Validator.check_schema()`).
   - Fields: `schema_version`, `id`, `synthetic`, `source` (VOD URL, round, annotator), `map`, `side`, `round_context` (spike status, time remaining, site region), `actors` (hp, armor, weapons, util references), `timeline` beats, and reactive `branches`.
   - Supports `"unknown"` sentinels on unobservable fields without schema errors.

2. **`tools/validate_scenario.py`**:
   - Validates JSON files against `scenario.schema.json` and runs semantic integrity checks:
     - All `start_region`, `spike_site_region`, and timeline/branch regions exist in the target map JSON (`world/maps/test_room.json`).
     - All actor utility IDs exist in `utility/abilities.json` (`smoke`, `flash`, `blind_wave`, `molly`, `scan_orb`).
     - Branch weights sum to `1.0` (tolerance `1e-6`).
     - Timeline beats are strictly non-decreasing by tick.
     - Flags fields with value `"unknown"` as informational warnings (use `--strict-unknown` to treat as errors).
   - Verified: Passes valid sample (exit 0); rejects bad regions, bad abilities, bad branch weights, and out-of-order timeline beats (exit 1).

3. **`tools/coords_to_region.py`**:
   - Pure function: `point_to_region(regions, [x, y, z]) -> Optional[str]` and `build_region_index(regions)`.
   - Uses Axis-Aligned Bounding Box (AABB) containment against map regions (`center` ± `size/2`).
   - Zero external runtime dependencies.

4. **`tests/test_coords_to_region.py`**:
   - 25 unit tests covering interior points, exterior points, ceiling/floor limits, AABB boundaries, first-match ordering, and invalid inputs.
   - **25/25 passing** (`pytest tests/test_coords_to_region.py -v`).

5. **`examples/scenario_sample_synthetic.json`**:
   - Clearly labeled synthetic sample scenario based on `test_room.json`. Used for validator acceptance testing.

---

### Track D — Local Speech-to-Text (Voice → Transcript)
*Committed and pushed to `person-3/voice-track` (latest commit `430cf31`).*

1. **`voice/stt.py`**:
   - Pure local/free STT using `faster-whisper` (CTranslate2 backend). No cloud or paid APIs.
   - **Model**: Defaults to `small.en` (244M params, `int8` CPU quantization) for high tactical callout accuracy. Configurable via `WHISPER_MODEL` env var (`base.en`, `small.en`, `medium.en`).
   - **Audio Normalization**: Automatically normalizes peak amplitude to `0.95` to fix quiet USB/headset mic recordings.
   - **Domain Vocabulary Conditioning**: Passes `initial_prompt` with VALORANT tactical syntax (`"2 pushing heaven, 1 B main, 3 rotating CT, flashing short, smoking mid, swing with me, defusing..."`) to prevent general-English misinterpretations.
   - **VAD & Hallucination Prevention**: Uses Silero Voice Activity Detection (`vad_filter=True`) + `repetition_penalty=1.1` to strip dead air and prevent Whisper from looping filler phrases during trailing silence.
   - **Direct Waveform Support**: Directly processes float32 in-memory numpy arrays, eliminating disk I/O bottlenecks and PyAV container errors.
   - **Function API**:
     ```python
     from voice.stt import transcribe
     # Pass audio_path, float32 numpy array, or None to record from mic:
     text, latency_s = transcribe(audio=None, audio_path=None, duration_s=4.0)
     ```

2. **`voice/push_to_talk.py`**:
   - CLI done-test harness:
     - Push-to-talk: `python -m voice.push_to_talk --key space` (hold SPACE to speak).
     - Timed mode: `python -m voice.push_to_talk --timed 4` (preloads model in RAM upfront, gives `3..2..1` warning beeps, high beep when mic opens, low beep when mic closes).
     - File mode: `python -m voice.push_to_talk --file clip.wav`.

3. **`voice/README.md`**:
   - Installation guide, environment variables, hand-off usage, and done-test results template.

---

## 3. How to Merge Voice Track into Kiro's Working Tree

From `C:\Users\Siddh\projects\callout-trainer` (on `person-3/comms-belief`):

```powershell
$GIT = "C:\Users\Siddh\AppData\Local\GitHubDesktop\app-3.6.5\resources\app\git\cmd\git.exe"
& $GIT fetch origin
& $GIT merge origin/person-3/voice-track -m "Merge Track D voice STT enhancements from person-3/voice-track"
```

Because `voice/` is completely orthogonal to `comms/`, `belief/`, and `annotations/`, this merges cleanly with zero conflicts.

---

## 4. Kiro's Next Tasks

Per `docs/PERSON3_KIRO_HANDOFF.md`:

1. **Step 3: Capability Spike (on target GPU PC)**
   - Verify local LLM runtime (Ollama or llama.cpp) running a quantized 7B–8B instruct model.
   - Measure tokens/sec and latency on a fixed tactical comm prompt.

2. **Step 4: Annotate Reference Round (`annotations/<scenario_id>.md`)**
   - Finish annotating the FNC vs PRX Lotus B final round (skeleton at `annotations/fnc_prx_lotus_b_final_round.md`, commit `48c5fe8`).
   - Mark starting positions, coarse timeline, and comm opportunities. Tag evidence sources and certainty without inventing facts off-screen.

3. **Step 5: Grounded LLM Interpreter (`comms/`)**
   - Cache grounding vocabulary from `valorant-api.com` (Lotus regions, agents, mapped ability primitives).
   - Build system prompt + 3–8 few-shot examples translating raw transcripts into structured `comms.v1` messages.
   - Test against typed text, then connect `voice.stt.transcribe()` as the live speech input source.

4. **Step 6: Wire into Beliefs & Decision Logging**
   - Connect interpreted comms to `belief/region_belief.gd` (note: trust model was removed; hedge is the only strength knob).
   - Implement `recording/decision_log.gd` to log all inputs, prompt, raw LLM output, and tick for non-deterministic fairness auditing.
