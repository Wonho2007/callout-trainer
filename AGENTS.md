# Instructions for AI collaborators

## Read first and establish current state

Read README.md, docs/PROJECT_DESCRIPTION.md, docs/PERSON2_HANDOFF.md,
docs/DECISIONS.md, docs/TEAM.md and docs/CONTRACTS.md before implementation. Inspect
`git status --short --branch` and the current commit. The current handoff provides
source revisions, commands, test scopes and next work. Do not infer completion from
historical documents or old test totals.

User instructions take precedence. The user made the six-hour final-sprint reassignment
authoritative, then required a plant start and enemies appearing only at their first
known annotation positions. The original six-hour budget is historical context, not
a fresh six-hour deadline each time a window opens. Do not invent remaining time.

Current work branch: `person-2/model-capability-spike`. Last gameplay checkpoint:
`608cae7`; newer documentation commits may follow. Preserve local/teammate edits.
Do not reset, clean, switch to obsolete lane branches or pull/merge blindly. PR #4
is already merged; old draft/no-merge directions for that PR are historical. Do not
merge the current branch to main without an explicit instruction.

## Ownership now

Person 1 has left. Person 2 owns the GPU PC's model/STT runtime, fair perception,
bots, physical execution, inherited world/greybox/spawning, scenarios, validation
and engine integration. Person 3 supplies interpretation/glue, beliefs, logging/audits,
annotation and demo support. Preserve Person 3's branch/checkouts; coordinate changes
to its implementation or shared schemas. Read docs/TEAM.md for the current split.

Godot **4.4.1 stable**, GDScript, Compatibility renderer are the implemented baseline.
Do not reopen engine choice. Use the existing data-driven builder and shared actor,
weapon, damage and utility components. Keep changes small and reviewable. The original
three-region map is preserved; the new seven-region approximation is a separate profile.

## Product rules

- First-person voice communication is core. Quick-call/typed fixtures are developer
  helpers, not the player communication UI. Local/free models; no training or paid
  API required. Keep the demo offline-capable.
- The measured sprint go/no-go selected **LLM interpretation + deterministic goal
  selection**. Experimental model goals remain opt-in and unaccepted after latency/
  validity failures. Keep their failing test distinct; never relax expiry to claim a pass.
- Fully accept valid delivered player testimony, even when wrong. No credibility/history
  feature or truth-based corroboration filter. Preserve explicit uncertainty, validation,
  clarification, delivery delay and physical limitations. The pinned belief implementation
  still has a documented hedge/full-acceptance gap; do not claim it fixed.
- The scene uses belief `57f809d` with the current planner compatibility field. Person 3
  `b84cc93` and `person-3/drop-trust-planner` contain the coordinated removal work.
  Review/test both consumers together before adopting it. Do not silently drop the field.
- Start the adaptation at the plant. Unknown enemies have no actor/collider until their
  first known annotated position. A remote utility effect does not locate its thrower.
  Current four arrivals are at +23s; Boaster alive at a recorded-death location is an
  explicitly labeled adaptation. Never force the recorded kills or outcome.
- Keep unknown source values unknown. Geometry/within-region coordinates are authored,
  source metadata is pending review, and player reference beats do not automate input.
  Grading/debrief/counterfactual/evaluation are deferred, not completed or permanently cut.

## Fairness boundary

Policy/model inputs are copied delayed observations, local beliefs, own allowed state
and explicitly public signals. No live target Nodes, hidden transforms, scene-tree
lookups, truth singletons, unrestricted event bus or player-only minimap/recon data.
Privileged sensing, spawning, physics and evaluator code may access the world, but
must not leak that access into policy. Fallback obeys the same limits.

Verify evidence ownership and actual delivery time, forbidden dependencies and unseen-
state perturbation. Audit actual recorded model contexts/prompts/raw outputs. A grep,
schema check, deterministic rerun or documentation check alone is not a fairness proof.
Registration/spawning must not inject a sighting or discard legitimate pending evidence.
Godot stamps message arrival ticks; STT/model processing must not backdate availability.

## Work, validation and handoff

Use existing runners and installed tools documented in docs/PERSON2_HANDOFF.md.
For docs changes run `python tools/check_repo.py` and `git diff --check`. For runtime
changes run the relevant Godot 4.4.1 suites and required Person 2 runner. Keep strict
engine-error checks and timeouts. Do not repeatedly broaden checks after they pass
without a new change or unresolved concern.

Humans verify controls, movement feel, visibility, spoken reactions and the exported
build. Separate human, synthetic/typed, headless and rendered-capture results. Never
claim export, offline acceptance, full fairness, pro fidelity, training benefit or
latency that was not measured in the stated configuration.

Update the **single current** docs/PERSON2_HANDOFF.md, relevant component guide and
docs/HANDOFFS.md with actual results, interface effects and remaining work. Replace
stale status rather than appending contradictory resume instructions. Historical
records are indexed in docs/ARCHIVE.md and retained in Git history.

No secrets, model weights, raw audio, private run logs, reference footage or ripped
assets in commits. No external editor-control plugins merely to avoid manual checks.
Do not add a repository code license without the owner's decision; check third-party
redistribution separately.
