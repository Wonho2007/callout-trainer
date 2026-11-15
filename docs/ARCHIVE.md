# Retired documentation

The hackathon demo's maintained documentation is the [README](../README.md),
[setup](SETUP.md), [architecture](ARCHITECTURE.md), [scenario](SCENARIO.md),
[communication contract](COMMANDS.md), [integration contracts](CONTRACTS.md),
and [testing guide](TESTING.md).

Sprint plans, Person 1/2/3 ownership assignments, AI resume prompts, accumulated
handoffs, model capability-spike notes and superseded setup guides were removed
from the working tree after the hackathon. They remain in Git rather than
competing with current instructions. Useful implementation details were consolidated
into the maintained guides; model/source pins remain in runtime code and architecture.

The pre-cleanup gameplay snapshot is `73cb362`, merged into main by `6175400`.
Use that immutable revision to inspect retired documents without changing checkouts:

```powershell
git show 73cb362:docs/PERSON2_HANDOFF.md
git show 73cb362:docs/DECISIONS.md
git show 73cb362:docs/TEAM.md
git show 73cb362:docs/PARALLEL_COMBAT_UI_HANDOFF.md
git show 73cb362:bots/VOICE_GAME.md
git show 73cb362:bots/SITE_SCENARIO.md
git show 73cb362:docs/COMMUNICATION_COACHING.md
git show 73cb362:docs/VIDEO_ANNOTATION.md
```

The source annotation is preserved at `b84cc93`; the earlier full project brief
and original integration records are at `608cae7`. Those documents describe their
original snapshots, not the finished demo's feature set or current permissions.

At cleanup, `person-2/combat-feedback-ui` remains separate by user instruction.
Its implementation notes and acceptance evidence stay on that branch. Kill
feedback/count, a health bar and unified result screens must not be documented
as part of main until integrated and verified.
