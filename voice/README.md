# voice/ — Local speech-to-text (Track D, Person 3)

Turns microphone audio into a transcript string + latency.
**Fully local and offline — no cloud/paid APIs.**

---

## What this module does

| In | Out |
|---|---|
| Microphone audio (push-to-talk) **or** a WAV/MP3 file | `(str, float)` — `(transcript_text, latency_seconds)` |

The transcript is **raw text only**. It does NOT interpret meaning, map to regions, or produce
structured comms — that is the Kiro interpreter's job.

---

## Engine choice: faster-whisper (CTranslate2)

| Property | Detail |
|---|---|
| Library | [faster-whisper](https://github.com/SYSTRAN/faster-whisper) |
| Backend | CTranslate2 (quantized inference, runs on CPU or CUDA) |
| Default model | `base.en` (~145 MB, English-only Whisper) |
| Model license | MIT (OpenAI Whisper weights) |
| Library license | MIT (faster-whisper), MIT (CTranslate2) |
| Network calls during transcription | **None** — model runs entirely locally |
| Swapping to a larger model | Set env var `WHISPER_MODEL=small.en` or `medium.en` |

Larger models (`small.en` ~460 MB, `medium.en` ~1.5 GB) give better accuracy at the cost of
higher latency. The GPU PC's discrete GPU should run `small.en` well under 500 ms.

---

## Install

```bash
# In the repo's .venv (already gitignored):
pip install faster-whisper sounddevice soundfile numpy keyboard
```

> **Model download (one-time, ~145 MB for base.en):**
> The first call to `transcribe()` automatically downloads the model from Hugging Face.
> After that, everything runs offline. The model is cached in `~/.cache/huggingface/hub/`.
> **Do not commit model files to git** (already covered by `.gitignore`).

---

## Usage from Python (Kiro interpreter hand-off)

```python
from voice.stt import transcribe

# Option A: record from mic for N seconds
text, latency_s = transcribe(duration_s=5.0)

# Option B: push-to-talk (hold key while speaking)
from voice.stt import record_until_keyup
wav_path = record_until_keyup(key="space")   # blocks until key released
text, latency_s = transcribe(audio_path=wav_path)

# Option C: transcribe an existing file
text, latency_s = transcribe(audio_path="clip.wav")

print(f"Transcript: {text!r}")
print(f"Latency:    {latency_s:.3f}s")
```

**Hand-off shape:** `transcribe()` returns `(str, float)`.
The Kiro interpreter receives `text` as its input. `latency_s` is for telemetry only.

---

## Running the done-test (Track D)

Run this on the **GPU PC** after installing the packages above.

```bash
# From repo root, with .venv active:
python -m voice.push_to_talk --loops 10
```

Speak one VALORANT-style callout per push-to-talk round. Suggested phrases:

1. "they're on heaven"
2. "flash short"
3. "I'm swinging B main"
4. "one left, spike is down"
5. "smoked out, don't peek"
6. "rotate CT, they're coming through mid"
7. "I got one, one left"
8. "defuse defuse defuse"
9. "quick peek, go go go"
10. "two B, one heaven, watch out"

For each round, record the printed output in the **Results** table below.

---

## Results (fill in after running on GPU PC)

> These results must be measured on the actual machine. Do not fill in estimated values.

| # | Spoken phrase | Transcript | Correct? | Latency (s) | Notes |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |
| 6 | | | | | |
| 7 | | | | | |
| 8 | | | | | |
| 9 | | | | | |
| 10 | | | | | |

**Summary (fill in):**
- Model: `base.en` / `small.en` / `medium.en` (circle one after testing)
- Device: CPU / CUDA (circle one)
- Median latency: ___ s
- Accuracy (correct / 10): ___/10
- Failure cases observed: ___

**Offline confirmed:** _(describe how verified — e.g. WiFi disabled, no network errors)_

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `WHISPER_MODEL` | `base.en` | Model size to load |
| `WHISPER_DEVICE` | `auto` | `auto` / `cuda` / `cpu` |
| `WHISPER_COMPUTE` | `default` | `float16` (CUDA) or `int8` (CPU) |

---

## Files

```
voice/
  __init__.py        exports transcribe()
  stt.py             core module — record + transcribe, returns (str, float)
  push_to_talk.py    CLI done-test helper
  README.md          this file
```

---

## What was built vs. what is NOT here

✅ Built: local mic capture, push-to-talk, file transcription, `(text, latency)` return  
✅ Built: model swap via env var, offline-capable  
❌ NOT here: meaning interpretation, region mapping, structured comms output — those are the Kiro interpreter's job  
❌ NOT here: model weight files (kept out of git; download once on target machine)
