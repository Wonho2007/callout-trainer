# Person 2 GPU capability spike — 2026-11-15

The user explicitly made `docs/FINAL_SPRINT_PERSON2.md` at Person 3 commit
`4c85f398239780322caf524681e225a64f5e7292` authoritative: approximately six hours,
two developers, Person 2 owns the GPU/model runtime and inherits Person 1's world work.
This completes the interpreter capability measurement, not the voice-to-action loop.

## Actual machine and configuration

| Field | Measured value |
|---|---|
| CPU / RAM | Ryzen 7 7700 / 33,454,374,912 bytes physical RAM |
| GPU / VRAM | NVIDIA GeForce RTX 4060 Ti / 16,380 MiB |
| Driver | 610.88; nvidia-smi CUDA UMD 13.3 |
| Runtime | Ollama 0.40.16, installed using winget; local server only |
| Model | llama3.1:8b, ID 46e0c10c039e, Q4_K_M, 4.9 GB download |
| Residency | ollama ps reports 100% GPU, 5.3 GB, context 4096 |
| Generation | Existing interpreter prompt, JSON format, temperature 0.0 |
| Interpreter source | Unmodified Person 3 snapshot at 4c85f39 |
| Vocabulary | Seven frozen region IDs, cached vocabulary; semantic run uses Yoru/Omen |
| Endpoint | **http://127.0.0.1:11434**; avoid localhost latency on this machine |

The [Meta Llama 3.1 license](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct/blob/main/LICENSE)
permits royalty-free use subject to its conditions; it is not an unrestricted permissive
license. Local prototype use requires no paid service. Distribution must retain the
required license/attribution and comply with its use conditions; weights are not committed.

## Measurements and verdict

| Check | Actual result |
|---|---|
| Initial model cold call, including first initialization | 44.52 seconds |
| Eight semantic checks using localhost | 8/8 correct, no fallback; median 2.620 seconds |
| Same eight checks using IPv4 loopback | **8/8 correct, no fallback; median 0.590 seconds** |
| IPv4 warm min / max | 0.314 / 0.608 seconds |
| IPv4 warm generation throughput | 52.09–54.36 output tokens/second |
| Supplied Person 3 spike runner, IPv4 | 7/8 schema-valid model outputs, 1/8 deterministic fallback; reported median 0.59 seconds |
| Snapshot interpreter + decision-log wrapper pytest suites | 27 passed |
| Main checkout documentation checker | Passed |

**Proceed with local LLM interpretation on this GPU.** Use IPv4 loopback and warm the
model before the round. The full LLM-decides go/no-go remains pending a real teammate
goal prompt/consumer measurement; interpretation timing cannot establish decision timing.
Keep the deterministic circuit breaker. No training/fine-tuning was performed.

The eight semantic checks cover three location/count/uncertainty reports, flash on cue,
follow-player swing, ambiguous flash clarification, unsupported plant, and a three-enemy
report. Most are prompt examples: this is a small capability smoke test, not a held-out
accuracy study. Warm throughput excludes prompt processing; latency includes the HTTP
request, prompt evaluation, generation and wrapper validation.

The supplied runner's ambiguous `swing site with me` generated an illegal target and
correctly fell back to clarification. In that same run, `they're pushing b main three of
them` and `one low in pit` produced an unspoken `unsure` hedge; `nothing on site` returned
empty. Those semantic limitations are **not** hidden by the 7/8 schema-valid count.
The three-enemy phrase was correct in both semantic runs, so do not assume perfect
repeatability even at temperature zero. Person 3 owns prompt/interpretation alignment;
this spike changes no Person 3 implementation, shared schema or belief behavior.

## Reproduce

PowerShell, from the repository root (Python 3.12.10 was installed locally):

```powershell
$pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
$spikeRoot = Join-Path $env:TEMP 'callout-model-spike-4c85f39'
New-Item -ItemType Directory -Force -Path $spikeRoot | Out-Null
git archive --format=zip --output "$spikeRoot\source.zip" 4c85f39
Expand-Archive -LiteralPath "$spikeRoot\source.zip" -DestinationPath "$spikeRoot\source" -Force
& $ollamaExe pull llama3.1:8b
& $pythonExe validation/model_capability_spike.py --source-root "$spikeRoot\source" --output runs/model-spike-llama31-8b-ipv4.json
Push-Location "$spikeRoot\source"
& $pythonExe docs/spike_measure.py --model llama3.1:8b --host http://127.0.0.1:11434
Pop-Location
& $ollamaExe ps
& $pythonExe tools/check_repo.py
```

Exact prompt/raw-output/token-timing records remain locally in gitignored
`runs/model-spike-llama31-8b.json` (localhost) and
`runs/model-spike-llama31-8b-ipv4.json` (IPv4). The `cold` record in the second file is
only the harness warmup call on an **already resident** model (0.686 seconds), not another
true cold-start measurement. The first run contains the actual cold load.

For wrapper tests, a disposable venv at `$spikeRoot\venv` contains pytest 9.2.0:
`python -m pytest tests/person3/test_interpreter.py tests/person3/test_decision_log.py -q`
was run from the extracted source. A preliminary unittest invocation failed because
pytest was absent; installing pytest in that venv and using the documented pytest
runner resolved the environment issue.

## Remaining sprint work

Live microphone/STT and offline transcription accuracy/latency are **unmeasured** and
remain central, never cut. Next connect the Person 3 live-ready bridge, check the actual
goal prompt/latency and full player-report acceptance, then implement the inherited
seven-region world/scenario integration. No game playtest, real spoken-comm run, export,
full model fairness audit or backup video is claimed here. Ollama remains serving locally;
the model uses Ollama's normal five-minute residency timeout.
