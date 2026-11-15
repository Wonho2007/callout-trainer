# Setup and troubleshooting

The supported hackathon configuration is Windows, Godot **4.4.1 stable** with the
Compatibility renderer, Python **3.12**, and an NVIDIA GPU with a compatible driver.
Speech recognition explicitly uses CUDA/float16; the supplied launchers do not
provide a CPU or macOS/Linux fallback. The demo was developed on an RTX 4060 Ti
16GB, Ryzen 7 7700 and approximately 32GB RAM; these are reference hardware, not
measured minimum requirements.

## 1. Clone with history

In PowerShell, from a directory where you keep projects:

```powershell
git clone https://github.com/Wonho2007/callout-trainer.git
cd callout-trainer
git fetch origin
```

Use a regular clone rather than a shallow clone or a downloaded source ZIP. The
launcher reads shared source from Git revisions `0260f28`, `57f809d`, and `b84cc93`.
Their roles are described in [architecture](ARCHITECTURE.md).

## 2. Install Godot

Install the standard Windows x86_64 **Godot 4.4.1 stable** build, including its
console executable. The voice launcher expects this exact location:

```text
%USERPROFILE%\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe
```

Create that directory and extract the matching Godot distribution there. For
developer test commands, `--godot` can point elsewhere, but the voice PowerShell
launcher currently uses the fixed user-cache path above. No export templates are
needed to run the source demo.

## 3. Create the Python voice environment

Install Python 3.12, then run from the repository:

```powershell
py -3.12 -m venv "$env:USERPROFILE\.cache\callout-voice-venv"
$voicePython = "$env:USERPROFILE\.cache\callout-voice-venv\Scripts\python.exe"
& $voicePython -m pip install -r validation/voice_runtime_requirements.txt
& $voicePython -c "from huggingface_hub import snapshot_download; print(snapshot_download('Systran/faster-whisper-small.en', allow_patterns=['config.json','model.bin','tokenizer.json','vocabulary.*']))"
```

Dependencies include faster-whisper, CTranslate2, microphone/keyboard capture and
NVIDIA cuBLAS/cuDNN runtime wheels. The host registers their DLL paths for its own
process. Model files live in the user's Hugging Face cache, outside the repository.
Internet access is needed for this initial installation and download.

## 4. Prepare the local language model

Install Ollama and ensure its local service is running at `http://127.0.0.1:11434`.
Download the default interpreter model:

```powershell
ollama pull llama3.1:8b
```

If the service is not already running, start `ollama serve` in another terminal.
Qwen is not required for the demo; `-ModelGoals` is an unsupported experimental
goal-selection mode and should be omitted for normal play.

## 5. Check the microphone, then launch

Select your microphone as the Windows default input and permit desktop microphone
access. Close older voice-host processes so only one captures push-to-talk.

```powershell
.\validation\run_live_voice.ps1 -Preflight
.\validation\run_voice_game.ps1
```

Preflight checks speech-model loading/CUDA. The full launcher also warms Llama,
creates a temporary integrated Godot project, opens the game and connects the voice
host on a per-launch localhost port. Wait for `Game connected` and `Hold V to speak`.
Hold V while speaking and release to submit. Capture is capped at 15 seconds.

Use F to restart, Esc to release the mouse, and close the game when finished.
The microphone host stops on game disconnect. See the [README](../README.md) for
controls and suggested calls. `run_live_voice.ps1 -Loops 5` is a standalone
microphone diagnostic; its results do not control the game.

## Troubleshooting

| Symptom | What to check |
|---|---|
| Missing Godot or voice environment | Verify the exact cache paths above; a system-wide installation is not automatically selected |
| Shared-source revision unavailable | Run `git fetch origin`; if using a shallow clone, fetch full history with `git fetch --unshallow origin` |
| Whisper is not cached | Rerun the model download command in the same voice environment/user account |
| CUDA DLL/model loading failure | Verify the NVIDIA driver and successful requirements installation; the default path requires CUDA |
| Interpreter model unavailable | Check the Ollama service and `ollama list`; pull `llama3.1:8b` if absent |
| Wrong or silent microphone | Check the Windows default input and permissions; run the standalone voice diagnostic |
| Game opens but no voice connection | Launch with `run_voice_game.ps1`, wait for warmup, and inspect the latest run logs |
| Unexpected teammate action | Check the actual transcript and submitted order, not just the model proposal; use a clear zone and repeat or cancel |
| Root certificate-store error under an agent sandbox | Run the unchanged test/launcher in normal permitted PowerShell; do not suppress engine errors to claim a pass |

Each launch writes `game.log`, `game-errors.log`, `events.jsonl`, and `models.jsonl`
under `runs/voice-game-<timestamp>/`. Events show the instruction actually submitted,
delivery, command lifecycle and changed decisions. Model records include the
transcript, exact prompts and responses. These may contain private speech content;
they are ignored by Git. Restart changes the round session and rejects stale replies.

## Delivery limits

The launchers reuse cached local weights after setup. Their presence on one machine
does not establish an offline installation on another. An integrated exported
executable containing the voice host/model runtime is not supplied by this setup;
exporting the root project alone does not package the playable voice scenario.
