# Contributing

1. Read [AGENTS.md](AGENTS.md), [project description](docs/PROJECT_DESCRIPTION.md) and
   [current handoff](docs/PERSON2_HANDOFF.md). Inspect status/branch before changing files.
2. Continue the current work on `person-2/model-capability-spike` unless assigned another
   task. Do not resume an obsolete branch merely because an archived guide names it.
3. Follow [current ownership](docs/TEAM.md). Person 2 inherited world/PC/engine work;
   coordinate changes to Person 3 code and shared contracts. Preserve teammate edits.
4. Keep changes small and reviewable. Run `python tools/check_repo.py`, whitespace checks
   and relevant runtime checks for code changes. Do not label documentation validation
   as a game/fairness test or headless/rendered evidence as a human playtest.
5. Update the single [current handoff](docs/PERSON2_HANDOFF.md), relevant component guide
   and [integration index](docs/HANDOFFS.md) with actual results and unresolved work.
6. Push the branch and use small PRs for review. PR #4 was already merged; the current
   branch has not been merged into main. Do not infer merge authorization from old records.

Do not commit credentials, caches, model weights, build outputs, raw audio, private run
logs, participant data, game assets or source footage. Local runtime logs are ignored.
Only deliberately sanitized fixtures belong in examples. Retain honest source uncertainty.

No blanket redistribution permission follows from an absent repository license. The
owner chooses the code license; third-party/model/asset terms must be checked separately.
The earlier three-person planning state is preserved in [history](docs/ARCHIVE.md).
