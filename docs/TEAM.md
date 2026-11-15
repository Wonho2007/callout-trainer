# Team ownership

Team GitHub handles: Wonho2007, sn-kurup and liedwin49. Wonho2007 has selected Person 2; Person 1/3 remain unassigned. These labels refer to developers, not characters in the simulation. The complete task split and timed acceptance gates are in project brief section 9.

| Lane | Owns | Must provide | Depends on |
|---|---|---|---|
| Person 1: world/player/delivery | world/, actors/, weapons/, utility/, scenes/maps/, scenes/player/, project.godot, main scene, export settings | Test room; named regions/spawns; shared mechanics; navigation bake; utility tests; map overlay geometry; offline build/video | Schemas from Person 3; bot integration from Person 2 |
| Person 2: perception/bots/scenario | perception/ (incl. hearing + reaction delay), bots/ (behavior + intent executor), scenarios/ (executable data + enemy pro-line/branches), validation/, scenes/bots/; policy/perception tests | Delayed perception and hearing; bot spawning; executes LLM/planner intent; enemy pro-line + reactive branches; fair executor; evidence trace; validator; deterministic fallback | World/action interfaces and bot spawning from Person 1; comm/belief/intent contract and decision log from Person 3 |
| Person 3: comms/belief/voice | comms/ (voice transcript + grounded LLM interpreter/decision core), belief/, recording/ (decision log), ui/, annotations/, grading/ + evaluation/ (deferred); shared schemas | Voice-to-structured-comm interpretation; belief the teammate adopts; non-deterministic LLM teammate decisions within the fairness boundary; decision logging; VOD annotation; grading/debrief later | Regions/events and bot spawning from Person 1; observations/hearing and the intent executor from Person 2 |

Directories above are reserved ownership boundaries; they are not claims that these modules already exist.

## Beginner-friendly agent workflow

Follow [docs/AGENT_WORKFLOW.md](AGENT_WORKFLOW.md). Person 1's first map is generated from world/maps/test_room.json by world/sandbox_builder.gd, with matching meshes/collision and named regions/spawns. Person 2 owns reusable bot behavior and scenarios; Person 3 coordinates debug visibility and the communication trace. The paths are proposed and not implemented.

Person 1 initially operates Godot; all three help playtest. Use synthetic fixtures while dependencies are unfinished. Integrate one callout-driven teammate response before recreating the source site.

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
