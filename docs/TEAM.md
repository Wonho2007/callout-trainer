# Team ownership

Team GitHub handles: Wonho2007, sn-kurup and liedwin49. Wonho2007 has selected Person 2; Person 1/3 remain unassigned. These labels refer to developers, not characters in the simulation. The complete task split and timed acceptance gates are in project brief section 9.

| Lane | Owns | Must provide | Depends on |
|---|---|---|---|
| Person 1: world/player/delivery | world/, actors/, weapons/, utility/, scenes/maps/, scenes/player/, project.godot, main scene, export settings | Test room; named regions/spawns; shared mechanics; navigation bake; utility tests; map overlay geometry; offline build/video | Schemas from Person 3; bot integration from Person 2 |
| Person 2: perception/bots/scenario | perception/, bots/, scenarios/, validation/, scenes/bots/; policy/perception tests | Bot spawning; delayed perception/hearing; validated physical LLM intent execution; deterministic fallback; executable baseline/reactive scenarios; evidence/feasibility checks | Shared world/action/bootstrap from Person 1; voice/intent/belief/log contract and verified notes from Person 3 |
| Person 3: voice/comms/belief/annotation | annotations/, comms/, belief/, recording/, ui/, shared schemas; grading/evaluation deferred | Local voice/STT and grounded LLM interpretation/goals; hedge-only beliefs; exact prompt/output logs; verified video notes | Regions/events from Person 1; copied available observations and physical intent executor from Person 2 |

**User-confirmed direction override (2026-11-14):** Person 3 owns voice/STT, grounded local LLM interpretation and teammate goal selection, hedge-only beliefs and exact prompt/output logs. Trust is removed; quick-call code is a test/fallback helper; grading/debrief/evaluation are deferred until the core works. Person 2 owns spawning in its bot/scenario scenes, delayed perception/hearing, validated physical intent execution, deterministic safety fallback and conversion of Person 3's verified notes. Person 1 owns shared player/main bootstrap, map/regions, mechanics/settings/export. The separate Person 2 first-person scene uses inherited shared scenes without editing those files; adopting it as the shared main remains Person 1 coordination. See [the updated Person 2 handoff](PERSON2_HANDOFF.md).

Directories above are reserved ownership boundaries; they are not claims that these modules already exist.

## Beginner-friendly agent workflow

Follow [docs/AGENT_WORKFLOW.md](AGENT_WORKFLOW.md). Person 1's first map is generated from world/maps/test_room.json by world/sandbox_builder.gd, with matching meshes/collision and named regions/spawns. Person 2 owns reusable bot behavior and scenarios; Person 3 coordinates debug visibility and the communication trace. The paths are proposed and not implemented.

Person 1 initially operates Godot; all three help playtest. Use synthetic fixtures while dependencies are unfinished. Integrate one callout-driven teammate response before recreating the source site.

## Video annotation ownership

Person 3 watches and annotates the videos using [the annotation guide](VIDEO_ANNOTATION.md), storing notes under annotations/. Person 2 converts verified notes into executable scenario JSON, scripts and reactive branches; Person 1 maps geometry/markers. Keep observed facts, uncertainty and authored alternatives separate. Begin with one short clip and hand over starting-state notes early.

## Work together first

Freeze region IDs, coordinates, collision masks, physics tick rate/order, availability timing, seeds, public information allowlist and schema version before parallel implementation. Use fake adapters and examples until dependencies land.

Person 1 coordinates engine version, root project configuration and the main scene. Person 3 coordinates schema definitions. Person 2 and Person 3 jointly implement the leak fixture before intelligence.

## Integration gates

- Hour 2: contracts, stubs and a failing forbidden-information fixture.
- Hour 6: navigable room; perception; beliefs/grading on shared fixtures.
- Hour 8: player callout changes teammate goal in-engine.
- Hour 12: end-to-end retake, fair bots, recording and score screen.
- Hour 16: trace/debrief and belief-only counterfactual.
- Hour 20: actual pilot results and offline export.
- Final two hours: freeze, rehearse and package.

These times follow the brief's unconfirmed 24-hour planning budget.

Person 3 has the heaviest UI/analysis workload. Person 1 supplies map drawing data and handles export/video; Person 2 owns validators/safety telemetry. Both help collect evaluation runs. Do not add optional speech/LLM work while the debrief remains incomplete.
