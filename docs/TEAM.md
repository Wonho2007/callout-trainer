# Current ownership

Updated 2026-11-15 from the user-selected final-sprint reassignment.

| Person | Current responsibility |
|---|---|
| Person 2 / Wonho2007 | GPU PC; local model and STT runtime; perception; bot policy/physical execution; inherited world/greybox/navigation/spawning; executable scenarios; validation; engine integration and final delivery work |
| Person 3 | Non-GPU interpretation/glue, working beliefs, shared schemas, logging/audits, annotation/source review and demo support |
| Person 1 | No longer active. Existing world/player/weapon/utility work is reused; Person 2 inherited the engine/world responsibility |

Do not wait for Person 1 to build the new world or operate the GPU. Do not rebuild
Person 3's interpreter/STT/logger when its supplied modules fit. Their source is consumed
read-only from pinned Git snapshots, not necessarily present as modules in this checkout.

Coordinate changes to Person 3's implementation and shared contracts. In particular,
trust-field removal must update the planner and belief snapshot together. Preserve other
branches/checkouts and all uncommitted work. Keep the original map available while the
new profile is developed. Current work branch and next steps: [handoff](PERSON2_HANDOFF.md).

The sprint began with approximately six hours and two people. No current remaining
deadline is inferred from that historical starting budget. The original three-person
hour-by-hour plan is preserved in [history](ARCHIVE.md).
