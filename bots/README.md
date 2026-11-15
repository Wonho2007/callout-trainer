# Bot and voice implementation

Start with the [user guide](../README.md), [architecture](../docs/ARCHITECTURE.md),
[scenario](../docs/SCENARIO.md) and [communication contract](../docs/COMMANDS.md).
Setup and test commands live in [setup](../docs/SETUP.md) and
[testing](../docs/TESTING.md); there is no active sprint handoff.

- `voice_host.py` / `live_voice.py`: local microphone, transcription, language
  interpretation, TCP transport and diagnostics.
- `teammate_runtime.gd`: trusted orchestration; owns delayed delivery, belief
  application, command/position/planner priority and physical dispatch.
- `knowledge_planner.gd`: pure deterministic coverage from bot-local beliefs.
- `command_executor.gd`: pure validated action lifecycle, readiness/cue and feedback.
- `annotation_policy.gd` / `annotation_executor.gd`: authored baseline beats and
  utility staging; `retake_policy.gd` supplies enemy reactive goals.
- `motion_controller.gd`: privileged own-actor navigation and authored jump execution.
- Flash/combat controllers: privileged physical adapters; combat policy consumes
  delayed sensory evidence instead of live opponent positions.
- `intent_gate.gd`: validates optional experimental model goals; not the default
  demo goal selector.

Keep world handles out of policy inputs. A delivered player position persists,
and a completed swing retains its actual endpoint. New orders/cancel and round
reset control that state; automatic spike fallback must not override player intent.
