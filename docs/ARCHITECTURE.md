# Architecture

Comm Bot combines a Godot simulation with a separate local Python voice process.
The game owns time, world state, validation and execution. The language model
interprets spoken intent; the supported demo uses deterministic goal selection.

## Components

| Component | Key files | Responsibility |
|---|---|---|
| Game launcher/project builder | `validation/run_voice_game.ps1`, `validation/run_person2_tests.py` | Warm models, assemble the temporary integration project, launch Godot and connect the voice host |
| Voice host | `bots/voice_host.py`, `bots/live_voice.py` | V-key capture, CUDA Whisper transcription, local Ollama interpretation, transport and telemetry |
| Engine bridge | `scenes/bots/voice_bridge.gd` | Session/request validation, authored target grounding, actual receipt timestamps, preparation and positioning guards |
| Bot orchestration | `bots/teammate_runtime.gd` | Deliver observations, apply reports, choose active control and dispatch physical execution |
| Commands | `bots/command_executor.gd` | Validate, stage, wait for readiness/cue, execute, cancel, expire and report physical completion |
| Perception | `perception/scene_sensor.gd`, `perception/perception_sensor.gd`, `perception/observation_inbox.gd` | World sensing, recognition/LOS/hearing rules and delayed copied observations |
| Planning | `bots/knowledge_planner.gd`, `bots/annotation_policy.gd`, `bots/retake_policy.gd` | Belief coverage, authored baseline and observed deviations |
| Physical adapters | `bots/motion_controller.gd`, flash/combat controllers | Navigate and jump, face authored points, aim from delayed evidence, fire and deploy utility |
| Shared gameplay | `actors/`, `scenes/player/`, `weapons/`, `utility/` | Actor physics, hitboxes, HP, damage, bullets and utility effects |
| Map/scenario | `world/site_builder.gd`, `world/maps/b_site.json`, `scenarios/site_coverage.json` | Source geometry, zones, authored navigation links, staging markers and arrivals |
| Presentation/records | `ui/minimap.gd`, `scenes/bots/teammate_info_panel.gd`, `recording/` | Player-facing information, teammate status and privileged gameplay events |

## Voice to physical action

1. Python captures audio while V is held. Whisper small.en transcribes it on CUDA;
   the grounded Llama 3.1 8B interpreter produces a report, command or clarification.
2. Python sends a proposal over localhost TCP. It cannot assign trusted simulation
   ticks or world coordinates. Godot validates the round session/request and maps
   named targets to public authored affordances.
3. Godot stamps receipt at its current bot tick plus one. The ordinary communication
   path delivers after another 18 ticks. Slow speech/model inference never backdates
   when a bot learned something.
4. The command executor consumes due messages. Reports update bot-local beliefs;
   actionable commands must satisfy actor state, inventory, reachability and timing.
5. The runtime dispatches movement, aiming and utility through shared physics.
   Completion comes from physical feedback, not from accepting an intent.

The host handles exact "go", "swing" and cancel cues without an extra model call.
The engine guards preparation phrases so "get ready to swing" cannot become an
immediate swing. Positioning imperatives use a local `player_position` observation
without expanding the shared `comms.v1` schema.

## Control priorities and persistent intent

An active validated command controls motion over autonomous planning. Otherwise,
a delivered player positioning goal takes priority over annotation, belief coverage
and optional model proposals. Explicit positioning holds its authored zone until
replaced or cancelled; completing a swing makes its reached route endpoint the new
position. Replayed completion results cannot restore an older goal. Flash actions
temporarily take control and then return to the held position.

Death and round completion stop execution. Restart replaces runtime/session state,
clears effects and pending actions, and rejects replies from older rounds. Early
cues and impossible/expired commands fail through their existing lifecycle rules.

## Information boundary

Policies consume copied, actually delivered observations, local beliefs, allowed
own-state and static map affordances. Sensors may inspect registered world actors;
physics may resolve collisions; spawning may materialize arrivals. Those privileged
handles never enter bot/model decision inputs. Enemy registration is not a sighting.

Vision requires range, view cone, exposure and collider LOS, with smoke/blindness
guards. Hearing yields coarse information rather than a hidden source transform.
Combat uses delayed torso samples and invalidates them after loss/age limits;
blinded bots cannot shoot. Player-only minimap and privileged recording truth are
separate from decision evidence. Details: [contracts](CONTRACTS.md) and
[perception](../perception/README.md).

## Why the game is assembled at launch

The root project is the original authoring scaffold. The runner constructs a
temporary project with the current scene/scripts plus read-only dependencies:

| Revision | Consumed source |
|---|---|
| `0260f28` | Shared actor/map/mechanics snapshot for the default site scenario |
| `57f809d` | GDScript belief module and its current compatibility contract |
| `b84cc93` | Python speech/interpreter/vocabulary/recording modules |

The runner overlays selected current local scripts onto the shared snapshot. A
new runtime file must be added to the copy lists to affect the launched demo.
`run_live_voice.ps1` extracts the Python source to
`%TEMP%\callout-voice-integration-b84cc93\source`. Keep Git history available.

The active scene inherits `site_playtest.gd` -> `lotus_playtest.gd` ->
`voice_playtest.gd` -> `first_person.gd` -> `scenes/main.gd`. The Lotus filename is
inherited implementation structure; the default geometry is the seven-zone B site.

## Logs and experimental paths

The Python host records transcripts, exact model requests/responses, submitted
orders, delivery and decision changes in ignored run directories. The privileged
game event bus serves recording/presentation, not unrestricted policy inputs.

`-ModelGoals` adds a separate local Qwen goal proposal path behind an evidence,
reachability and expiry gate. That experiment missed the two-second context budget
and is outside demo acceptance. It is not needed for voice commands. The pinned
belief module also retains a documented hedge/full-acceptance mismatch; an inert
`trust` compatibility field is not an implemented credibility feature. Neither
limitation should be described as fixed by the UI or positioning changes.
