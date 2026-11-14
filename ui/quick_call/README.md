# Quick-call UI (Person 3)

Mandatory deterministic quick-call menu (brief 6.6, AGENTS.md). This is the required
fallback input; speech/LLM interpretation is stretch and comes later.

## Pieces

- `../../comms/quick_call.gd` ? pure model. Builds the menu and validated `comms.v1`
  report/command/cue/cancel messages from a fixed scenario vocabulary. No scene,
  world or wall clock. A trusted caller assigns message/actor IDs and ticks.
- `quick_call_panel.gd` / `quick_call_panel.tscn` ? thin `Control` view. Renders the
  flattened menu, emits `message_selected(message)` on a pick and shows short
  lifecycle acknowledgments. Owns no belief/executor state and does not edit the
  main scene.

## Host wiring (not part of this lane's files)

The panel does not reach the world. A host scene is expected to:

1. `configure(speaker_id, recipient_id, region_ids, entry_marker_ids, flash_marker_ids, tick_provider, expiry_ticks)`
   using the shared region registry (Person 1) and authored entry/flash markers.
2. Connect `message_selected` to a trusted adapter that assigns the reaction delay,
   builds a told observation (`comms/report_adapter.gd`) and queues it in the
   addressed bot's Person 2 inbox. The message must never reach beliefs early.
3. Feed Person 2 executor result objects back via `show_result(status, reason_code)`.
   Never render "Ready" before the executor reports `ready`.

## What is verified vs. not

- Automated (headless, when a Godot 4 stable executable is available):
  `tests/person3/quick_call_tests.gd` checks the model's menu, message building,
  rejection of unknown region/hedge/target/timing, and the acknowledgment mapping.
  `tests/person3/belief_goal_integration.gd` drives a delayed quick-call through
  Person 2's real executor/inbox/planner so a report changes a bot goal.
- Not verified here: rendering, mouse/keyboard input and on-screen layout. The
  `.tscn` builds its child nodes in code; a human must open the scene, confirm the
  list renders and selection fires, and judge usability in a playtest. Headless
  script runs do not establish any of that.
