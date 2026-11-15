# comms/ — grounded LLM interpreter + decision core (Person 3)

Turns a VALORANT comm (typed now, voice later via `voice/stt.py`) into a validated
`comms.v1` **proposal**: intent/target/timing for a command, or region/count/hedge for a
report. A trusted adapter (Person 2 side) later stamps `message_id`, `speaker_id`,
`recipient_id`, `issued_tick`, `expires_tick`. The interpreter never invents IDs, ticks,
coordinates, or regions outside the frozen vocabulary.

## Files

| File | What it does |
|---|---|
| `vocabulary.py` | Builds the compact grounding vocabulary the model gets as context. Holds the **placeholder** sandbox region ids + aliases and the ability→primitive map. |
| `vocabulary_cache.json` | Committed cache from valorant-api.com (Lotus callouts, agents+abilities, weapons). Lets the interpreter run fully offline. |
| `fetch_vocabulary.py` | Refreshes `vocabulary_cache.json` from valorant-api.com (needs network; run once). |
| `interpreter.py` | The LLM wrapper: system prompt + few-shot, pluggable `OllamaClient`, `comms.v1` output validation, and the **required deterministic circuit breaker** fallback. |
| `report_adapter.gd`, `quick_call.gd` | Existing GDScript `comms.v1` builders/validators (deterministic menu/fallback path). |

The decision log is in `recording/decision_log.py` (+ `.gd`).

## Design rules honored (docs/COMMANDS.md, AGENTS.md)

- Only `swing_together`, `throw_flash`, `report_enemy` exist (+ `cue`/`cancel`). Any other
  ask → honest `unsupported`, never invented behavior.
- Ambiguous region/target → `clarify` (one short question), never a guess, never coordinates.
- Report `count` is a positive int or `null`; **never** inferred as 1 from "someone".
- The deterministic parser is the **circuit breaker**: if the model is offline, times out,
  returns junk, or emits an illegal token (region not in vocab, bad timing, count ≤ 0), the
  interpreter falls back to it inside the same boundary. The fallback obeys the same vocab.

## Not frozen yet

`vocabulary.REGION_IDS` is a **placeholder** list of generic Lotus B callouts
(`REGIONS_FROZEN = False`). No pro position is invented. When Person 1 freezes the real
Lotus B region ids (seam #1), replace `REGION_IDS` + `REGION_ALIASES` and re-run the tests.
Entry/flash marker ids (Person 1) are also pending; until then a command `target_id` must be
a known region id.

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

- `pytest tests/person3/test_interpreter.py tests/person3/test_decision_log.py` — 27 + ...
  passing (wrapper parse/validation, circuit breaker, clarify/unsupported, no-infer-one).
- End-to-end smoke over the real cache produces correct proposals for reports, both
  commands, clarify and unsupported.
- **Not** verified here: real model latency/accuracy — that needs the GPU PC. See
  `docs/CAPABILITY_SPIKE.md`.
