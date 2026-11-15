# Current agent workflow

Read [AGENTS.md](../AGENTS.md) and [the current handoff](PERSON2_HANDOFF.md). The
project already has a running prototype; this is no longer a kickoff/build-from-zero task.

1. Inspect current status, branch, code and real dependency revisions. Preserve edits.
2. Choose one concrete remaining acceptance gap from the handoff. Coordinate shared
   interfaces rather than replacing teammate modules.
3. Implement a small reviewable increment using existing shared mechanics and code/data
   generated scenes. Do not add editor-control plugins to avoid simple manual checks.
4. Run checks appropriate to the change. Keep engine errors/timeouts strict. Documentation
   changes need the repo checker; don't rerun the engine merely to edit prose.
5. For human acceptance, provide the actual launcher and specific spoken/actions checklist.
   Headless/typed/rendered evidence cannot be relabeled as a human success.
6. Update the single current handoff and relevant component guide. Preserve prior evidence
   through Git history instead of appending contradictory resume instructions. Push
   reviewable changes; do not assume permission to merge main.

Person 2 owns PC/model/STT/engine/world work; Person 3 provides non-GPU components.
The selected sprint configuration uses LLM interpretation with scripted goal selection.
Current source/ownership/limits are in [the project description](PROJECT_DESCRIPTION.md)
and [team guide](TEAM.md). The earlier three-person beginner plan is in [history](ARCHIVE.md).
