# Demo script & honest labeling (Person 3)

The demo chain is: **player speaks → STT text → grounded LLM interprets → belief updates →
teammate reacts.** Person 3 owns everything from the transcript to the belief snapshot and
the decision-log/fairness trace. Person 2 runs the mic/model/engine on the PC.

## Run it

```powershell
# headless rehearsal (no GPU/engine, deterministic fallback path)
.\.venv\Scripts\python.exe tools\demo_trace.py

# on the PC with a local model
.\.venv\Scripts\python.exe tools\demo_trace.py --model llama3.1:8b
```

Live demo on the PC: replace each typed line with a spoken comm into the mic; `voice/stt.py`
produces the transcript, `Transcript.from_stt(text, latency_s, started_s)` adapts it, and the
rest of the trace is identical.

## The trace to narrate (measured, deterministic rehearsal)

```
[t= 1s] "two b main"              -> report  b_main count=2 hedge=sure   (belief -> b_main)
[t= 2s] "i think one more b main" -> report  b_main count=1 hedge=think  (belief -> b_main 0.99)
[t= 3s] "flash that smoke"        -> clarify "Flash where?"              (no guess)
[t= 4s] "maybe one cubby"         -> report  b_cubby count=1 hedge=unsure
[t= 5s] "go defuse the spike"     -> unsupported "no 'defuse' action"    (honest no)
teammate belief (enemy e1): b_main 0.990  — the bot now expects the enemy on B main
fairness audit over the decision log: 5 records, OK
```

Talking points, in order:
1. **Voice is the only input.** The player talks; the teammate hears, interprets, reacts.
2. **Grounded, not trained.** The model is handed the vocabulary (7 frozen Lotus B region ids
   + agents + the ability→primitive map) and a strict schema at runtime. No fine-tuning, no
   VALORANT dataset, free/local only.
3. **Belief moves on hedge.** "sure/think/unsure" → 0.9/0.7/0.4 strength; two B-main calls
   drive the belief to 0.99 on B main. No per-speaker trust model — a wrong call commits the
   bot and the consequence is a bad round, which is the teaching signal.
4. **It refuses to hallucinate.** Ambiguous "flash that smoke" → one clarifying question, never
   a guessed region or coordinate. An action we do not support ("defuse") → an honest no.
5. **The circuit breaker is visible.** If the model is offline, times out, or emits an illegal
   token, the trace shows `source=deterministic_fallback` and still produces a valid comm. The
   demo works with or without the GPU.
6. **Fairness is proven, not asserted.** Every interpret/decide logs the copied inputs, the
   prompt, the raw output, the parsed result, the source and the tick. The audit checks over
   that log that every cited evidence id was available by its tick, no truth/scene/spectator
   key ever reached the inputs, and unseen enemy movement cannot change an allowed output.

## Honest labeling — do NOT overclaim

- Say **"grounded, not trained."** Never "trained on pro comms" or "learned from VALORANT".
- Say branches are **"pro-inspired adaptation"** from the annotated VOD round, authored and
  weighted and synthetic — not a reproduction of what the pros did.
- The fallback firing is a **feature with a visible reason**, not a failure to hide.
- **No** transfer, win-rate, "measured savings", or research-citation claims. Report only what
  the trace shows. The greybox and scenario are synthetic and labeled synthetic.

## Backup video (help Person 2 record)

If the live model/mic is flaky on the day, record a real spoken-comm run on the PC in advance:
the mic path producing transcripts, the belief bars moving, the fallback firing at least once
with its reason shown, and the fairness audit printing OK. If even that is unavailable, the
headless `tools/demo_trace.py` output above is the labeled fallback — state clearly it is the
deterministic path, not a live-model run.
```
