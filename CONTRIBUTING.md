# Contributing

Read the [README](README.md), [repository instructions](AGENTS.md),
[architecture](docs/ARCHITECTURE.md), and [contracts](docs/CONTRACTS.md).
Inspect status and other worktrees; create a feature branch from the intended base
without disturbing another contributor's checkout. Main represents the hackathon
demo. The separate combat UI branch has not been integrated into that baseline.

Keep gameplay changes small and use existing shared actor, weapon, utility and
navigation components. Runtime files must reach the temporary integration project
through the runner's copy/overlay lists. Coordinate changes to the pinned Python
source, belief module and shared schemas across all consumers.

For documentation, run `python tools/check_repo.py` and `git diff --check`.
For code, also run the appropriate suites in [testing](docs/TESTING.md). Report the
source revisions and exact scope of results; documentation checks are not gameplay
or fairness tests, and automated checks are not human acceptance.

Update maintained guides when behavior/setup changes. Do not add sprint handoffs
or resume prompts; earlier notes remain in Git and the [archive index](docs/ARCHIVE.md).
Use reviewable commits and only push or merge when authorized.

Keep secrets, model weights/caches, raw audio, run logs, participant data, build
outputs and source footage out of Git. Raw audio stays in memory in the voice
path; diagnostic transcripts/prompts may still be private. Only sanitized fixtures
belong in examples/tests.

This independent simulator does not access a game client or use extracted assets.
An absent repository license does not grant blanket redistribution permission;
the owner selects the code license. Check third-party package, model and asset
terms separately. In particular, do not bundle downloaded model weights without
reviewing their applicable terms; experimental Qwen use is not required by the demo.
