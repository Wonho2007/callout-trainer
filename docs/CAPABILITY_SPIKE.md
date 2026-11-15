# Capability spike — local LLM on the GPU PC (Person 3, Step 3)

**Goal:** before committing to the LLM path, prove a free/local model answers the
VALORANT-comms prompt **fast enough to react mid-round**, with correct structured output.
Budget 30–60 min. Run this **on the target GPU PC** — the numbers from a laptop/CPU are not
representative. The interpreter and its tests already run offline on any machine; this spike
only measures the model half.

This is a RUNBOOK, not a result. No latency/accuracy number is claimed until someone runs
the steps below on the real hardware and records them in the table at the bottom.

## 1. Install a local runtime (free, offline after pull)

Easiest is **Ollama** (<https://ollama.com>). Alternatives: llama.cpp, LM Studio.

```powershell
# after installing Ollama, it runs a local server on http://localhost:11434
ollama --version
```

## 2. Pull a small instruct model that fits the VRAM

Pick one that fits the card and is free-licensed. Good 7–8B starting points:

```powershell
ollama pull llama3.1:8b        # Meta Llama 3.1 8B instruct (Llama license — confirm use is allowed)
# or, smaller / permissive:
ollama pull qwen2.5:7b-instruct
ollama pull mistral:7b-instruct
```

Confirm the model's license is free for your use before committing to it. Record which model
you picked.

## 3. Measure with the project's own prompt

The interpreter builds the exact system + few-shot prompt. Measure latency and check the
output is valid by running the interpreter against the running model:

```powershell
# from the repo root, with the .venv active
.\.venv\Scripts\python.exe docs\spike_measure.py --model llama3.1:8b
```

(`docs/spike_measure.py` is below — it times N fixed comms through `OllamaClient` and reports
latency + how many produced valid, in-vocabulary output vs. fell back to the deterministic
parser.)

## 4. Pass / fail

- **Pass:** a usable model returns valid structured output on the hand examples with a
  per-comm latency low enough to react in a round (rule of thumb: interpret in well under a
  second once warm; the final countdown "go" uses the fast deterministic cue path anyway, so
  interpret latency has some slack). Proceed to wire the model into `comms/interpreter.py`
  (already done — just point `OllamaClient(model=...)` at it).
- **Fail:** if it is too slow or the output is wrong, try a smaller model or a tighter
  schema, and tell the team the latency reality **before** committing. The deterministic
  circuit breaker means the demo still works without the model.

## 5. Record the result here (fill in after running)

| Field | Value |
|---|---|
| Date / who ran it | _TBD_ |
| GPU PC (CPU/GPU/VRAM) | _TBD_ |
| Runtime + version | _TBD_ |
| Model + quantization | _TBD_ |
| Model license OK? | _TBD_ |
| Warm per-comm latency (median of N) | _TBD_ |
| Tokens/sec | _TBD_ |
| Valid-output rate on the N hand comms | _TBD_ |
| Verdict (proceed / smaller model / simplify) | _TBD_ |

> Do not mark this spike "passed" in HANDOFFS.md until this table is filled from a real run.
