# Live voice to a Godot teammate — synthetic integration

Run from this checkout in PowerShell:

```powershell
.\validation\run_voice_game.ps1
```

The launcher warms Llama 3.1 8B, starts Godot 4.4.1 and opens the default microphone
host. Hold **V**, speak, release. **F** restarts the round. Close the game and
voice console when done. Microphone audio stays in memory; transcripts, exact model
prompts/outputs, actual delivery events and changed decisions are in ignored
`runs/voice-game-<timestamp>/`. The new bounded capture loop also exits on game
disconnect and caps a recording at 15 seconds. Player death does not gate the host.

## Current scope and vocabulary

The default uses the imported seven-zone [B site scenario](SITE_SCENARIO.md).
Reports use its actual region names; commands map only to authored swing routes.
The original room/entry/corridor fixture remains an explicit `-LegacyRoom` option.

**Preparation and release are separate:** ?get ready to swing? (or ?get ready to
swing Heaven?) prepares an `on_cue` command. The engine bridge enforces that timing
even if the interpreter mistakenly proposes `now` or `follow_player`. The teammate
can move to its staging position, reports `ready`, and waits. A separate ?swing?
or ?go? releases the ready command after the normal delivery delay. ?Cancel? cancels
it. An unresolved target still requires clarification; preparation never invents a
route. Explicit ?swing now? retains immediate-command timing when interpreted as such.

Final swing/go/cancel interpretation uses the existing deterministic cue path.
Early cues, expired commands, invalid targets and stale round sessions retain their
existing guards. Preparation timing adjustments are recorded in the actual submitted
event as `timing_guard: preparation_waits_for_cue`; raw model logs remain unchanged.
Flash routes exist only in the legacy room configuration, not the current B site.

**Selected sprint scope:** local LLM interpretation with the deterministic knowledge
planner as the primary goal selector. The sprint handoff expressly permits this
go/no-go result when full model decisions fail latency/validity requirements. This
does not claim a working LLM-decides loop. The original physical intent gate and
information-limited fallback remain intact.

Experimental `-ModelGoals` enables the additional local Qwen 2.5 3B goal host.
It is **not accepted for the demo**: current external-model tests miss the existing
two-second context budget, and the full-goal fixture remains a failing check. Qwen
3B uses the [Qwen research license](https://ollama.com/library/qwen2.5:3b/blobs/b5c0e5cf74cf),
which limits the downloaded model to non-commercial research/evaluation without a
separate commercial license. It was evaluated locally; no weights are committed or
redistributed. The selected default uses Llama and does not require Qwen.

## Clock, policy boundary and recovery

- Godot listens only on 127.0.0.1, on a per-launch port. Only copied released runtime
  contexts and static marker/watch affordances leave the privileged scene. No scene
  handles, opponent transforms, minimap or private event archive is sent to a model.
- Python interprets outside the physics thread. It returns a proposal, not trusted
  IDs/ticks or world coordinates. Godot stamps its real current tick plus one when
  the proposal arrives. The inbox then imposes 18 ticks of reaction delay. Speech
  processing cannot backdate actual availability.
- Transport request IDs deduplicate retries. A new round creates a new session;
  late old-round speech/goal replies cannot operate the new actor. The recorder
  preserves source time and actual delivery tick separately.
- Experimental goals still pass the existing context/evidence/reachability/expiry
  gate. Invalid outputs, timeouts, lost heartbeat or disconnect relinquish model
  control. The model sees authored marker/watch pairs, never arbitrary destinations.
- The real physics/mechanics remain shared. This change adds no special damage,
  sight, movement, utility or player-credibility rule.

The Python Person 3 interpreter/log source is consumed unchanged from `b84cc93`.
The scene's existing belief dependency remains `57f809d`, with current planner
compatibility, until the coordinated trust-field/belief integration is adopted.
Its documented hedge/full-acceptance gap is not fixed here. We deliberately do not
use the headless Python belief mirror's immediate future-tick application as a
live simulation clock. Root settings, shared world/mechanics and Person 3 source
are unchanged. The launcher pins shared game source `8712f7d` for reproduction.

## Actual validation — 2026-11-15

- Godot `4.4.1.stable.official.49a5bc7b6`, official Windows console build installed
  under `~/.cache/callout-godot-4.4.1`.
- Existing default/cross-lane suites: **552 assertions pass** (505 owned + 47
  integrations), shared source `8712f7d` / belief `57f809d`.
- Existing FPS smoke before bridge: **41 pass**. New real TCP bridge smoke:
  **22 pass**, including delayed movement, available copied context, actual intent
  gate, retry deduplication, disconnect fallback, reset and old-session suppression.
- Python boundary tests: **4 pass**, covering future/foreign/duplicate evidence,
  unsupported goals, hidden targets, invalid watch regions, stop payloads and no
  microphone opening after an idle host has disconnected.
- Real model external integration, `--interpret-only`: **pass**, model-source
  interpretation, actual told delivery and physical teammate movement verified.
  Typed transcript injection (“one enemy in room”), not a microphone claim.
  That run's interpretation took 2.282s; do not substitute the earlier standalone
  0.590s latency or claim constant end-to-end timing under game load.
- Actual recorded-boundary audit passes: 33 contexts, 28 changed decisions,
  157 delivered observations and one model interpretation. Cited evidence must
  have actually been delivered by that tick. This is not a full-game fairness proof.
- Full goal mode: **not passing**, separately recorded. Initial short timeout
  canceled cold initialization; preloading fixed that. Unconstrained Llama goal
  samples took 2.870/3.845s and could mismatch marker/watch. Structured marker/watch
  pairs and the smaller Qwen evaluation still timed out at 3s in the concurrent
  engine run. Existing two-second context expiry was preserved, not extended to
  make a pass. Logs remain in `runs/voice-model-*`.
- Known shared runtime navigation-bake GPU readback warning remains. No engine or
  script errors in passing scene checks. Human spoken game acceptance is recorded
  below only when confirmed; no export, seven-region scenario, full-game fairness,
  OS-network-disabled test or training benefit is claimed.

Reproduce the passing checks:

```powershell
$pythonExe = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$godotExe = "$env:USERPROFILE\.cache\callout-godot-4.4.1\Godot_v4.4.1-stable_win64_console.exe"
$sourceRoot = "$env:TEMP\callout-voice-integration-b84cc93\source"
& $pythonExe validation/run_person2_tests.py --godot $godotExe --voice-smoke --person1-ref 8712f7d --person3-ref 57f809d
& $pythonExe validation/run_voice_model_smoke.py --godot $godotExe --source-root $sourceRoot --interpret-only
& "$env:USERPROFILE\.cache\callout-voice-venv\Scripts\python.exe" -m pytest tests/person2/test_voice_host.py -q
& $pythonExe tools/check_repo.py
```

Omit `--interpret-only` to reproduce the separate unaccepted full-goal test; it
must return nonzero when model goals do not satisfy its evidence/physics conditions.
The voice environment/setup is described in [LIVE_VOICE.md](LIVE_VOICE.md).
