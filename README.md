# Callout Trainer

A first-person communication practice game built in Godot. The player speaks to an
information-limited teammate: a local speech model transcribes the call, a local LLM
interprets it, and the teammate responds through delayed observations, beliefs and
shared game mechanics. The purpose is to practice clear, timely tactical communication.

The current prototype is a **plant-hold adaptation** with seven named regions. The
player takes the Something/Yoru role and the teammate the f0rsakeN/Omen role from
Person 3's notes. It starts when the spike is planted. Four enemies whose starting
locations are unknown remain absent until their first known positions at **+23s**.
Geometry and within-region coordinates are authored approximations; source metadata
is pending review. This is not a verified reconstruction or a prediction of pro play.

## Start here

- [Project description and requirements](docs/PROJECT_DESCRIPTION.md)
- [Current Person 2 handoff](docs/PERSON2_HANDOFF.md)
- [Prompt for a new Codex window](docs/CODEX_RESUME_PROMPT.md)
- [Current team/integration status](docs/HANDOFFS.md)
- [Repository instructions](AGENTS.md)

These documents describe current work. [Historical documents](docs/ARCHIVE.md) are
evidence and background, not instructions to resume old branches or repeat old tasks.

## Run on the configured Windows PC

Open PowerShell. Close any older voice-host console, then paste:

```powershell
cd "C:\Users\Isoto\Documents\GitHub\callout-trainer"
.\validation\run_voice_game.ps1
```

Hold **V** to talk, **F** to restart at the plant, **Esc** to release the mouse.
WASD moves, LMB fires, R reloads and B dashes. V only talks. Enemies arrive at +23s.
The default uses Person 3's seven-zone map, including circular Pit and the zone
minimap. `-Lotus` also selects this new default; `-LegacyRoom` / `-LegacyLotus`
explicitly select the older profiles. Running the root
Godot project directly still opens the original scaffold, not the voice-enabled scenario.

Use **Godot 4.4.1 stable**. The launcher uses the installed local Python environment,
cached Whisper weights and Ollama. Setup and limits: [voice setup](bots/LIVE_VOICE.md),
[voice/game bridge](bots/VOICE_GAME.md), [scenario details](bots/SITE_SCENARIO.md).

## Current implementation

- Local Whisper speech recognition and grounded Llama 3.1 8B interpretation; no paid API
  or training is required. Voice is the player communication path.
- **Deterministic goal selection is the selected sprint configuration.** Experimental
  LLM goal generation missed the context budget and is opt-in, not accepted for the demo.
- Copied delayed perception, evidence IDs, smoke/flash restrictions, shared navigation,
  rifle/combat, command lifecycle, an authored reactive branch and round/reset handling.
- Imported seven-zone B site map, circular-region precedence, late enemy registration and first-known spawn checks.
- Local transcripts, exact model inputs/outputs and delivery/decision telemetry.

## Evidence and remaining work

Recorded checks include 552 default/cross-lane assertions, 139 live-perception checks,
31 scenario checks and seven Python authoring/voice-boundary tests. Five standalone
human microphone calls were interpreted correctly (one cue/queue transcription spelling
error). A real-model typed engine fixture verifies delayed delivery and physical movement.
Rendered scenario captures were inspected. These results have distinct scopes; they do
not establish a full human voice-to-Lotus playtest or full-game fairness.

Still open: human scenario acceptance, exact ally/utility baseline reenactment,
coordinated belief/schema alignment, source review, offline/export acceptance and a
backup video. Grading, debrief, counterfactuals and evaluation are deferred product work.
No win-rate, learning-transfer or professional-behavior claim is made.

Current work is on `person-2/model-capability-spike`; last gameplay checkpoint `608cae7`.
PR #4 was already merged earlier. This branch has not been merged into `main`.

No game-client access, extracted assets or replay-file scraping. Independent simulator;
not affiliated with Riot Games. Model weights, raw audio and local logs stay outside Git.
