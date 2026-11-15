# PC live voice acceptance tool

This standalone tool runs Person 3's unchanged `voice.stt` and grounded interpreter
from commit `b84cc93` on the PC. It does not dispatch proposals into Godot or apply
the headless belief mirror. The next game bridge must stamp real simulation ticks,
preserve actual delayed availability and validate authored target IDs.

## Run the installed setup

From the repo in PowerShell:

```powershell
.\validation\run_live_voice.ps1 -Preflight
.\validation\run_live_voice.ps1 -Loops 5
```

Hold **Right Ctrl**, speak one callout, then release. Read the transcript and interpreted
result before the next call. Ctrl+C exits. Audio is recorded only while the key is held;
raw audio stays in memory. Local transcript, exact prompt/raw output and timing records
are written to gitignored `runs/live-voice.jsonl`. These diagnostic sequence numbers are
not game ticks. The source recorder does not return key-down time; the tool records
capture completion and post-capture latency, not an invented utterance timestamp.

Use the Windows default microphone (currently Razer headset). Suggested acceptance set:

1. “Two on heaven.”
2. “I think someone's B main.”
3. “Maybe one in pit.”
4. “Flash heaven on my cue.”
5. “Swing main with me.”

Record what was actually spoken and compare count, location, uncertainty and timing.
Don't infer human accuracy from a synthesized voice or headless test. Current scene
targets and the seven frozen vocabulary regions still require coordinated mapping.

## Setup on another Windows GPU machine

Use Python 3.12 and Ollama serving `llama3.1:8b` at `http://127.0.0.1:11434`:

```powershell
python -m venv "$env:USERPROFILE\.cache\callout-voice-venv"
$voicePython = "$env:USERPROFILE\.cache\callout-voice-venv\Scripts\python.exe"
& $voicePython -m pip install -r validation/voice_runtime_requirements.txt
& $voicePython -c "from huggingface_hub import snapshot_download; print(snapshot_download('Systran/faster-whisper-small.en', allow_patterns=['config.json','model.bin','tokenizer.json','vocabulary.*']))"
ollama pull llama3.1:8b
.\validation\run_live_voice.ps1 -Preflight
```

Whisper is explicitly CUDA/float16; no torch install or silent CPU selection. The launcher
uses cached local weights and the Python process sets `HF_HUB_OFFLINE=1`. DLL search paths
are local to that process. NVIDIA cuBLAS/cuDNN wheels supply the CUDA libraries; the
machine still needs a compatible NVIDIA driver. Weights are MIT-licensed Whisper weights,
kept in the user's Hugging Face cache outside Git. This setup has not yet been verified
with networking disabled at the OS level.

The virtual environment lives outside the repository because the documentation checker
scans untracked Markdown files too; an in-repo environment made it inspect third-party
package documentation. No repository checker or third-party package was modified.

## Actual checks — 2026-11-15

- CTranslate2 4.9.0 / faster-whisper 1.2.1, small.en snapshot
  `d1d751a5f8271d482d14ca55d9e2deeebbae577f`, CUDA float16 on RTX 4060 Ti.
- Default microphone enumerates as Razer headset; device enumeration is not an audio test.
- GPU preflight loads and executes silence transcription: empty transcript, 0.173s
  first run (total model preflight 2.136s); second process 0.052s (0.781s preflight).
- Synthetic Windows SAPI file “Two on heaven.” -> “2 on heaven.” -> model report
  b_heaven / count 2 / sure. STT 0.668s; total after file capture 1.298s. This exercises
  real CUDA speech inference and local Llama, not a microphone or accuracy benchmark.
- Unmodified Person 3 snapshot interpreter/log/pipeline/audit suites: 47 passed.
- Five live human samples completed on the default Razer microphone. User confirmed
  the only wording error was cue -> queue. All five model interpretations correctly
  preserve region/count/uncertainty or action/timing. Median STT 0.138s; median total
  key-release-to-interpretation 0.718s (range 0.679–0.881s). No fallback in these five.
  This is a five-phrase manual smoke test, not a general accuracy estimate.
- Broader microphone accuracy, offline-with-network-disabled test, game bridge,
  full player-report acceptance, model goal prompt/timing and exported build remain
  unverified. Existing pipeline retains hedge-weighted Bayesian beliefs; do not claim
  it fixes full acceptance or use its immediate future-tick application as a live clock.

| Spoken phrase | Actual raw transcript | Interpretation | STT / after-release total |
|---|---|---|---|
| two on heaven | 2 on heaven. | b_heaven, 2, sure | 0.285 / 0.881s |
| I think someone's B main | I think someone's B main. | b_main, unknown count, think | 0.139 / 0.707s |
| maybe one in pit | Maybe one in pit. | b_pit, 1, unsure | 0.125 / 0.737s |
| flash heaven on my cue | Flash heaven on my queue. | throw_flash, b_heaven, on_cue | 0.138 / 0.718s |
| swing main with me | Swing main with me. | swing_together, b_main, follow_player | 0.126 / 0.679s |

Person 3 supplies interpretation/glue/fairness. This Person 2 PC tool changes none of
that lane's source. Required deterministic interpreter fallback remains active.
