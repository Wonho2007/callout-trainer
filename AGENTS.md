# Repository instructions

This repository contains the finished source-based Comm Bot hackathon demo.
Start with [README.md](README.md), [setup](docs/SETUP.md),
[architecture](docs/ARCHITECTURE.md), [scenario](docs/SCENARIO.md),
[contracts](docs/CONTRACTS.md), and [testing](docs/TESTING.md).

## Working safely

- Inspect git status, current HEAD and worktrees before editing. Preserve existing
  changes and other workers' checkouts. Use a feature branch for new work.
- Main is the demo baseline. Historical Person 1/2/3 lane assignments, sprint
  deadlines and resume prompts are retired; they are not continuation instructions.
- Do not merge or push without user authorization. Do not reset, clean, blindly
  pull, or overwrite teammate work. The combat UI branch is separate from the
  current main build; do not silently integrate it during documentation work.
- Use Godot 4.4.1 stable, GDScript and the existing shared actor/mechanics and
  data-driven map. Keep changes small. Read the runner copy lists before adding
  runtime dependencies: the demo is assembled from pinned snapshots plus overlays.

## Product and information rules

- Voice is the player communication path; typed/quick-call fixtures are developer
  tools. Local Whisper/Llama interpretation plus deterministic goals is the demo
  configuration. Full model goals are an unaccepted opt-in experiment.
- Policies/models may consume only copied delivered observations, local beliefs,
  permitted own-state, authored static affordances and public round outcomes.
  Never provide live enemy Nodes/transforms, unrestricted truth/event streams,
  player-only minimap data or private recon. Privileged adapters may sense and
  resolve physics without passing their handles into decisions.
- Validate evidence ownership and actual delivery time. Godot stamps receipt;
  slow model work cannot backdate knowledge. Registration must not invent sightings.
- Valid player reports are intended to be accepted even when wrong, preserving
  explicit uncertainty. No credibility/history or truth-corroboration filter.
  The pinned belief implementation retains a documented hedge/full-acceptance
  mismatch; do not claim it fixed or change shared contracts in one consumer only.
- Preserve plant-start/+23s first-known enemy arrivals, unforced outcomes,
  physical movement/utility, preparation/cue timing and persistent player intent.
  Do not replace unknown source values with guesses or claim exact pro fidelity.

## Verification and documentation

- Docs changes: run `python tools/check_repo.py` and `git diff --check`.
- Runtime changes: use relevant Godot suites plus the required bot runner in
  docs/TESTING.md. Retain strict engine-error checks and existing timeouts.
- Distinguish automated, rendered and human evidence. Never claim export, offline
  acceptance, full fairness, latency or training benefit without the corresponding
  measurement. Do not repeatedly broaden tests after they pass without a reason.
- Update the relevant maintained guide rather than creating another handoff or
  resume prompt. Historical notes are available through docs/ARCHIVE.md and Git.
- No credentials, model weights, raw audio, private logs, recordings, ripped game
  assets or generated builds in commits. Sanitize deliberate test fixtures.
  The owner chooses any repository license; third-party terms remain separate.
