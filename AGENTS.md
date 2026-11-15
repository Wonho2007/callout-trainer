# Instructions for AI collaborators

## Read before changing code

Read the complete callout_trainer_brief.md, then docs/TEAM.md, docs/CONTRACTS.md, docs/DECISIONS.md and docs/HANDOFFS.md. Inspect git status and the assigned issue. User instructions take precedence. The brief is authoritative for product requirements; record conflicts rather than silently dropping requirements.

This repository begins as documentation and examples only. Never claim a runnable Godot project, implemented bots, passing fairness tests or collected evaluation data until those actually exist.

## Scope and ownership

Use Godot 4. Do not reopen engine choice. Exact editor version must be pinned by Person 1 at kickoff with the team. Typed GDScript is the proposed default, not a confirmed event rule.

Know which lane the user assigned. If no lane is assigned, inspect open issues and make safe independent progress; clarify before making cross-lane implementation choices. Do not overwrite others' edits.

- Person 1 owns world/, actors/, weapons/, utility/, scenes/maps/, scenes/player/, main scene, project.godot and export settings.
- Person 2 owns perception/ (including hearing and reaction delay), bots/ (behavior and the intent executor), scenarios/ (executable scenario data and enemy pro-line + branches), validation/, scenes/bots/ and bot/perception tests.
- Person 3 owns comms/ (voice transcript input and the grounded LLM interpreter/decision core), belief/, recording/ (including the non-deterministic decision log), ui/, grading/ and evaluation/ (deferred), annotations/ (VOD notes), shared schemas and belief/log tests.
- Shared contracts and fixture changes require explaining the change to both consumers in the PR and updating docs/examples together. Do not treat proposed examples as already frozen APIs.

Use short-lived lane branches and small reviewable PRs. Keep shared root settings/main scene edits under Person 1's coordination. GitHub issues track work; docs/HANDOFFS.md records current integration facts.

## Agent-led construction and human review

Read docs/AGENT_WORKFLOW.md. The team has no engine experience and prefers code-generated scenes/data with minimal manual authoring. Person 1 owns world/sandbox_builder.gd and world/maps/ for static geometry; Person 2 owns scenario actors/branches separately. Start with a JSON-generated synthetic room and reusable actors; create matching collision and navigation, then integrate one communication moment before pro-site detail.

Implement short increments with explicit acceptance criteria and real launch/check commands. Agents may create scenes, scripts, data/settings and run Godot when available. Humans verify movement, rendering, input, sightlines, bot reactions and the exported build. Keep automated results separate from manual playtest records; never infer manual success from headless logs. If executable or visual access is unavailable, state it and provide reproducible teammate steps.

Do not add external editor-control plugins or complex asset workflows merely to avoid a few manual checks. Preserve the current ownership boundaries and all final acceptance requirements.

## Fairness boundary

Policy receives copied, delayed observations, its own state, local beliefs and explicitly allowed public round signals. No live target Node references, hidden transforms, global truth singleton or unrestricted scene-tree/event-bus reads.

Perception and privileged physics/evaluator/replay code may access the world; their truth must not leak into policy. Policy uses target IDs and last observed data. Fallback bots obey the same restrictions.

Write the leak-test fixture before bot intelligence. Verify evidence IDs existed and were available at the decision tick; also check forbidden dependencies and unseen-state perturbation. A grep alone is not a complete proof. Never mark the fairness gate passing just because the documentation checker passes. Because the LLM is non-deterministic, prove fairness against the **recorded decision log** (every input the model was given, its prompt and output) rather than by re-running to the same result: the logged inputs must be a subset of what the bot could observe by that tick, and must contain no hidden truth.

## Product constraints

Build one compact first-person scenario with useful comms and explainable bot adaptation. Player input is **voice**; there is no quick-call menu (the menu code is retained only as a deterministic test/fallback helper). Teammate bots are driven by a **local LLM that interprets comms and makes decisions non-deterministically**, using only information the bot is allowed to have. The LLM is grounded in the game's vocabulary at runtime, not trained or fine-tuned, and must be free/local with no paid service. A deterministic policy/behavior-tree fallback is required as the circuit breaker when the model is unavailable or produces an illegal intent (hierarchical control: the model interprets and sets goals, a deterministic executor carries them out).

Do not remove the brief's never-cut features without an explicit product decision. Post-round grading and the belief-only counterfactual are **deferred** by a product decision (build after the core voice→LLM→reaction loop works); they are not cut. Entropy reduction does not establish accuracy. Never invent pro behavior, measured savings, win-rate improvement, research citations or transfer evidence.

Use synthetic fixtures for unresolved map/clip details and label them. No client access, ripped assets, replay-file scraping, secrets or paid required services. Keep the demo offline-capable.

## Validation and handoff

Run python tools/check_repo.py for documentation/contracts/examples changes. Run meaningful Godot checks once implemented, using the pinned editor and documented commands; report unavailable checks honestly. Avoid unrelated tests or dependencies.

Each handoff includes changed paths, interface/schema effects, real commands/results, remaining dependency and next integration step. Update the owning lane's row in docs/HANDOFFS.md. A handoff update is not permission to mark unfinished work complete.

Do not add a code license without the repository owner's decision; available source is not permission to redistribute third-party assets.
