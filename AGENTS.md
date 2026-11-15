# Instructions for AI collaborators

## Read before changing code

Read the complete callout_trainer_brief.md, then docs/TEAM.md, docs/CONTRACTS.md, docs/DECISIONS.md and docs/HANDOFFS.md. Inspect git status and the assigned issue. User instructions take precedence. The brief is authoritative for product requirements; record conflicts rather than silently dropping requirements.

The repository began as documentation and examples. Person 2's isolated delayed inbox/command executor now has headless tests and a fake actor demo; read docs/PERSON2_EXECUTOR.md for exact scope. Do not claim a playable sandbox, speech interpreter, full-game fairness, real physics integration or evaluation data from those tests.

## Scope and ownership

Use Godot 4. Do not reopen engine choice. Exact editor version must be pinned by Person 1 at kickoff with the team. Typed GDScript is the proposed default, not a confirmed event rule.

Know which lane the user assigned. If no lane is assigned, inspect open issues and make safe independent progress; clarify before making cross-lane implementation choices. Do not overwrite others' edits.

- Person 1 owns world/, actors/, weapons/, utility/, scenes/maps/, scenes/player/, main scene, project.godot and export settings.
- Person 2 owns perception/, bots/, scenarios/, validation/, scenes/bots/ and bot/perception tests.
- Person 3 owns annotations/ for verified video notes, comms/, belief/, grading/, recording/, ui/debrief/, evaluation/, shared schemas and belief/log tests.
- Shared contracts and fixture changes require explaining the change to both consumers in the PR and updating docs/examples together. Do not treat proposed examples as already frozen APIs.

Use short-lived lane branches and small reviewable PRs. Keep shared root settings/main scene edits under Person 1's coordination. GitHub issues track work; docs/HANDOFFS.md records current integration facts.

## Agent-led construction and human review

Read docs/AGENT_WORKFLOW.md. The team has no engine experience and prefers code-generated scenes/data with minimal manual authoring. Person 1 owns world/sandbox_builder.gd and world/maps/ for static geometry; Person 3 owns video annotation notes in annotations/; Person 2 converts them to executable scenario actors/branches in scenarios/. Follow docs/VIDEO_ANNOTATION.md. Start with a JSON-generated synthetic room and reusable actors; create matching collision and navigation, then integrate one communication moment before pro-site detail.

Implement short increments with explicit acceptance criteria and real launch/check commands. Agents may create scenes, scripts, data/settings and run Godot when available. Humans verify movement, rendering, input, sightlines, bot reactions and the exported build. Keep automated results separate from manual playtest records; never infer manual success from headless logs. If executable or visual access is unavailable, state it and provide reproducible teammate steps.

Do not add external editor-control plugins or complex asset workflows merely to avoid a few manual checks. Preserve the current ownership boundaries and all final acceptance requirements.

## Fairness boundary

Policy receives copied, delayed observations, its own state, local beliefs and explicitly allowed public round signals. No live target Node references, hidden transforms, global truth singleton or unrestricted scene-tree/event-bus reads.

Perception and privileged physics/evaluator/replay code may access the world; their truth must not leak into policy. Policy uses target IDs and last observed data. Fallback bots obey the same restrictions.

Write the leak-test fixture before bot intelligence. Verify evidence IDs existed and were available at the decision tick; also check forbidden dependencies and unseen-state perturbation. A grep alone is not a complete proof. Never mark the fairness gate passing just because the documentation checker passes.

## Product constraints

The user confirmed the newer direction documents from Person 3's `b078210` as authoritative in this session. Read [Person 2's direction handoff](docs/PERSON2_HANDOFF.md), [Person 3's core handoff](docs/PERSON3_KIRO_HANDOFF.md) and [parallel tracks](docs/PERSON3_ANTIGRAVITY_HANDOFF.md). Their direction overrides older planning defaults below and in the brief.

Build a first-person comms coach with voice-only player comms and local, free LLM teammate decisions. Person 3 owns voice/grounded interpretation, model goal generation, beliefs and model prompt/output logging. Person 2 owns fair perception and physical intent execution. Keep the deterministic planner as a required safety fallback; quick-call code is a test/fallback helper, not the player input UI. No training or paid API is required. Teammates always fully trust valid, delivered player comms, even when wrong. No credibility/history score, corroboration prerequisite or numeric credibility discount based on a hedge; preserve explicit player uncertainty as content, with clarification and physical/delivery checks intact. Keep the compatibility `trust: {}` field until both consumers coordinate a schema change.

Grading/debrief and the belief-only counterfactual are deferred until the core voice-to-reaction loop works, not removed from the eventual product. Never invent pro behavior, measured savings, win-rate improvement, research citations or transfer evidence. Source clip/year/timestamps still require Person 3's verified notes. With nondeterministic model decisions, audit the exact recorded inputs/prompt/output; deterministic policy perturbation tests alone cannot establish full model fairness.

Use synthetic fixtures for unresolved map/clip details and label them. No client access, ripped assets, replay-file scraping, secrets or paid required services. Keep the demo offline-capable.

## Validation and handoff

Run python tools/check_repo.py for documentation/contracts/examples changes. For Person 2 runtime changes also run validation/run_person2_tests.py with --godot pointing to Godot 4.4.1 stable; see docs/PERSON2_EXECUTOR.md. Run meaningful Godot checks once implemented, using the pinned editor and documented commands; report unavailable checks honestly. Avoid unrelated tests or dependencies.

Each handoff includes changed paths, interface/schema effects, real commands/results, remaining dependency and next integration step. Update the owning lane's row in docs/HANDOFFS.md. A handoff update is not permission to mark unfinished work complete.

Do not add a code license without the repository owner's decision; available source is not permission to redistribute third-party assets.
