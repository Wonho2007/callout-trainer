# Integration handoffs

Initial state: planning documents and synthetic examples only. No Godot project, tests, bot scenes, gameplay logs or evaluation results exist.

| Lane | Current state | Next deliverable | Blocker / dependency |
|---|---|---|---|
| Person 1 | Not started | Pin Godot version; JSON-driven synthetic room/builder, actor stubs and blank desktop export | Confirm target hardware and shared contracts |
| Person 2 | Not started | Delayed observation interface and leak-test fixture with Person 3 | Shared contracts; use fake world adapter |
| Person 3 | Not started | Freeze schemas; fake run and evidence/time checks | Shared contracts; use synthetic fixture |

Update only the facts for your lane. Append a short handoff using:

- Branch/PR and owning lane:
- Changed files:
- Interface/schema changes and consumers:
- Actual checks run and results:
- Remaining work/dependency:
- Next integration step:

Do not record a check as passed when it was unavailable. The repository documentation check is not the leak test. Keep participant data, raw recordings and secrets out of handoff notes.

## Planning update: agent-led development

The brief and docs/AGENT_WORKFLOW.md now specify code-generated map geometry and short agent tasks for a beginner team. Person 1 starts with the synthetic room; Persons 2/3 integrate the communication fixture before site detail. Separate automated checks from human playtest evidence. No Godot implementation or manual playtest is claimed by this documentation update.

## Handoff notes

### 2026-11-14 — Person 1: Godot editor version pinned

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `docs/DECISIONS.md`, `docs/HANDOFFS.md`.
- Interface/schema changes and consumers: none yet. Version pin affects future `project.godot`, export presets and any version-specific API use; relevant to all lanes once the project exists.
- Actual checks run and results: `python tools/check_repo.py` not run locally (Python 3 unavailable on this machine); change is documentation-only with no new markdown links or fixture edits. CI docs workflow will run the check on push.
- Remaining work/dependency: Wonho2007 and sn-kurup must install the same Godot 4.4.1 stable build and confirm; install matching 4.4.1-stable export templates; confirm launch on target hardware. Pin remains a Person 1 proposal until the team confirms.
- Next integration step: create `project.godot`, the JSON-driven synthetic test room (`world/maps/test_room.json` + `world/sandbox_builder.gd`), actor stubs and a blank desktop export.

### 2026-11-14 — Person 1: synthetic test room + first-person player (stage 1)

- Branch/PR and owning lane: `person-1/world-scaffold`; Person 1 (world/player/delivery).
- Changed files: `project.godot`, `icon.svg`, `world/maps/test_room.json`, `world/sandbox_builder.gd`, `scenes/main.tscn`, `scenes/main.gd`, `scenes/player/player.tscn`, `scenes/player/player.gd`.
- Interface/schema changes and consumers: introduces the synthetic map data shape (meters, Y up, `[x,y,z]`, box center + full-extent size) and placeholder region IDs (`region_a`/`region_b`/`region_mid`) and spawn roles. Region IDs/graph and coordinate convention are NOT frozen — to be aligned with Persons 2/3 before freeze (see docs/CONTRACTS.md). `sandbox_builder.gd` exposes `get_spawn(role)` and `map_data`.
- Automated checks run and results: project opens in Godot 4.4.1 stable (Compatibility renderer); builder reports 8 geometry nodes, 3 regions, 3 spawns built from `test_room.json`; `python tools/check_repo.py` not run locally (Python 3 unavailable on this machine) — change is mostly code, docs edits add no new links.
- Manual playtest and results: tester confirmed in-editor playtest — room renders (floor, 4 walls, 3 cover crates), first-person movement (WASD + mouse look), wall/cover collision, walk/crouch/jump, Esc mouse capture toggle, and R restart all work. Not yet tested as an exported build.
- Remaining work/dependency: navigation bake (NavMesh) not yet implemented — separate next Person 1 step; no actors beyond the player; no weapons/damage/smoke/flash/defuse; no desktop export yet. Region IDs pending team freeze.
- Next integration step: bake navigation on the generated geometry (NavigationRegion3D + NavigationMesh), then add actor stubs and a blank desktop export.
