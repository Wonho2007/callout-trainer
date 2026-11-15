# comms/ — grounded LLM interpreter + decision core (Person 3)

Turns a VALORANT comm (typed now, voice later via `voice/stt.py`) into a validated
`comms.v1` **proposal**: intent/target/timing for a command, or region/count/hedge for a
report. A trusted adapter (Person 2 side) later stamps `message_id`, `speaker_id`,
`recipient_id`, `issued_tick`, `expires_tick`. The interpreter never invents IDs, ticks,
coordinates, or regions outside the frozen vocabulary.

## Files

| File | What it does |
|---|---|
| `vocabulary.py` | Builds the compact grounding vocabulary the model gets as context. Holds the **7 frozen Lotus B region ids** + aliases and the ability→primitive map. |
| `vocabulary_cache.json` | Committed cache from valorant-api.com (Lotus callouts, agents+abilities, weapons). Lets the interpreter run fully offline. |
| `fetch_vocabulary.py` | Refreshes `vocabulary_cache.json` from valorant-api.com (needs network; run once). |
| `interpreter.py` | The LLM wrapper: system prompt + few-shot, pluggable `OllamaClient`, `comms.v1` output validation, and the **required deterministic circuit breaker** fallback. |
| `pipeline.py` | End-to-end glue: transcript → `interpret()` → `comms.v1` → told observation (reaction delay) → belief update → snapshot. The live-mic transcript drops into the same call. |
| `report_adapter.gd`, `quick_call.gd` | Existing GDScript `comms.v1` builders/validators (deterministic menu/fallback path). |

The decision log is in `recording/decision_log.py` (+ `.gd`); the fairness audit is in
`recording/fairness_audit.py`.

## Design rules honored (docs/COMMANDS.md, AGENTS.md)

- Only `swing_together`, `throw_flash`, `report_enemy` exist (+ `cue`/`cancel`). Any other
  ask → honest `unsupported`, never invented behavior.
- Ambiguous region/target → `clarify` (one short question), never a guess, never coordinates.
- Report `count` is a positive int or `null`; **never** inferred as 1 from "someone".
- The deterministic parser is the **circuit breaker**: if the model is offline, times out,
  returns junk, or emits an illegal token (region not in vocab, bad timing, count ≤ 0), the
  interpreter falls back to it inside the same boundary. The fallback obeys the same vocab.

## Frozen vocabulary

`vocabulary.REGION_IDS` is the **7 frozen Lotus B scenario region ids** (`REGIONS_FROZEN =
True`): `b_main`, `b_cubby`, `b_heaven`, `b_upper`, `b_pit`, `c_link`, `a_link`
(annotation §2). No pro position is invented; these are the informal community callouts the
scenario uses. Person 1 still owes each a world-space Area3D bound; the
`tools/coords_to_region.py` helper bridges coordinates to ids. A command `target_id` must be
a known region id until Person 1 supplies entry/flash marker ids.

## Transcript hand-off (so the live mic plugs in with no rework)

The interpreter/pipeline consumes a transcript the same way whether it is typed or spoken:

```python
from comms.pipeline import CommsPipeline, PipelineConfig, Transcript

pipe = CommsPipeline(PipelineConfig(bot_id="omen_bot", scenario_agents=["Omen"]))

# typed (headless tests):
pipe.handle_text("two b main", timestamp_s=1.0)

# live mic (Person 2's PC): voice.stt.transcribe() returns (text, latency_s)
text, latency_s = transcribe()                     # from voice/stt.py
pipe.handle(Transcript.from_stt(text, latency_s, started_s=utterance_start_wall_s))
```

**Shape to confirm with Person 2:** a transcript is `{text: str, timestamp_s: float}` where
`timestamp_s` is when the comm was *spoken* (utterance start), not when STT finished.
`PipelineConfig.tick_rate_hz` converts it to `issued_tick`. Nothing else about the source
matters — same call for typed and mic. The `voice/` module already returns `(text, latency_s)`,
so only the utterance-start wall-time needs wiring on the PC.

**Hand-off confirmed against the real STT (person-3/voice-track):** `voice.stt.transcribe()` is
typed `-> tuple[str, float]` returning `(transcript, latency_s)` — exactly what
`Transcript.from_stt(text, latency_s, started_s)` consumes, no adapter rework. One integration
detail for Person 2: `latency_s` is measured "from the START of transcription, not recording",
so it is **not** the utterance clock. Pass `started_s` = the wall-time recording began (the
`>>> LISTENING NOW` instant for `--timed`, or key-down in `record_until_keyup`), captured in
`voice/push_to_talk.py`, not the post-transcription `datetime.now()` the CLI currently prints.
With that one value, the mic path is drop-in.

## Run

```powershell
# refresh the vocabulary cache (needs network, run once)
.\.venv\Scripts\python.exe comms/fetch_vocabulary.py --map Lotus

# interpret typed text (deterministic fallback, no model needed)
.\.venv\Scripts\python.exe -c "from comms import interpreter as I, vocabulary as V; print(I.interpret('two on heaven', V.build_vocabulary()))"

# with a local model (Ollama running — see docs/CAPABILITY_SPIKE.md)
.\.venv\Scripts\python.exe -c "from comms import interpreter as I, vocabulary as V; c=I.OllamaClient('llama3.1:8b'); print(I.interpret('two on heaven', V.build_vocabulary(), c))"

# tests (offline, no model)
.\.venv\Scripts\python.exe -m pytest tests/person3/test_interpreter.py tests/person3/test_decision_log.py -q
```

## Verified (offline, this machine)

- `pytest tests/` — **72 passing**: interpreter wrapper (parse/validation, circuit breaker,
  clarify/unsupported, no-infer-one), decision-log shape + truth-leak rejection, the
  transcript→belief pipeline (every branch + belief math mirroring `region_belief.gd`), the
  fairness audit (availability, no-leak, perturbation), and coords_to_region.
- `python tools/demo_trace.py` — runs the full chain headless: reports concentrate belief on
  `b_main` (0.99), a clarify, an honest unsupported, 5 decision-log records, fairness audit OK.
- **Not** verified here: real model latency/accuracy and live mic — those need the GPU PC. See
  `docs/CAPABILITY_SPIKE.md` and `docs/DEMO_SCRIPT.md`.
