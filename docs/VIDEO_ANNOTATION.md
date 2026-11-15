# Video annotation handoff

**Owner: Person 3**, assigned by the user. Person 3 watches and annotates the videos. Person 2 converts the verified notes into executable scenario JSON, baseline plans and observation-driven branches. Person 1 builds the relevant layout and markers.

## First deliverable

Start with one short retake segment chosen with the team. Do not annotate whole matches or every frame. Store notes in annotations/<scenario_id>.md; this path belongs to Person 3. scenarios/ remains Person 2's executable-data ownership. No clip has been selected or annotated by this documentation update.

For each clip, record:

- Source URL, match/round/map/site, clip start/end timestamps, annotator and review status.
- Player takeover role and the compact area required in the sandbox.
- Initial actor regions, spike/timer, visible health and remaining utility; mark unknown values explicitly.
- A short timeline of actor locations, movement goals, angle holds, utility, entry, defuse and deaths.
- Relevant cover/elevation/sightlines and region names agreed with Person 1.
- Player-observable communication opportunities: enemy reports, utility planning before entry, readiness, corrections and death reports.
- Which facts each participant could know; spectator/minimap information is not automatically participant knowledge.
- Simplifications for reduced actors, uncertain geometry, approximate timings and utility primitives.

## Annotation table template

| Clip timestamp / relative time | Actor | Observed region/action | Evidence source | Certainty / unknowns | Possible communication opportunity |
|---|---|---|---|---|---|
| <timestamp / seconds> | <actor> | <visible fact> | <POV / minimap / HUD> | <observed / inferred / unknown> | <opportunity or none> |

Keep observation separate from inference. If an agent helps inspect frames or draft notes, Person 3 verifies the result against the source and records unresolved uncertainty. Do not invent off-screen positions, remaining utility, exact coordinates or team voice communication absent from the footage.

Suggested alternative responses are authored branches, not observed pro behavior. Label them accordingly; Person 2 is responsible for their feasibility and execution.

## Handoff and review

- Person 3 supplies verified notes and source timestamps, including uncertain fields and graded-opportunity candidates.
- Person 1 maps named regions/markers and checks whether the required geometry fits the sandbox.
- Person 2 turns notes into executable data, verifies travel times/visibility/actions and adds reactive guards/fallbacks. Failed validation returns a concrete question to Person 3 rather than silently changing the source facts.
- Person 3 verifies that coaching only expects information the player could reasonably know. Death position and killer location are distinct; shooter identity is required only if knowable.
- All agree which simplifications require the label "pro-inspired adaptation."

Deliver the first usable starting-state/timeline notes early so Persons 1/2 can proceed; complete later details in parallel. Keep annotation small rather than delaying the playable integration for exhaustive analysis.

Reference public video by URL/timestamp. Do not commit or bundle VOD footage, extracted game assets or scraped replay files. Do not claim an exact pro replay from incomplete video evidence.
