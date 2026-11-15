# Current decisions and open items

Updated 2026-11-15. User instructions are authoritative; old planning records are in
[ARCHIVE.md](ARCHIVE.md). The [project description](PROJECT_DESCRIPTION.md) separates
product requirements from current implementation and acceptance evidence.

| Topic | Current decision/status |
|---|---|
| Product | First-person voice communication practice; player comms change an information-limited teammate's behavior |
| Engine | Godot 4.4.1 stable, GDScript, Compatibility renderer |
| Team | Person 1 left; Person 2 inherits world/engine work and runs GPU/model/STT; Person 3 supplies non-GPU components/support |
| Hardware | Ryzen 7 7700, RTX 4060 Ti 16GB, approximately 32GB RAM; no longer TBD |
| Model stack | Local Whisper small.en CUDA/float16; Ollama/Llama 3.1 8B grounded interpretation; no training/paid API requirement |
| Measured go/no-go | **LLM interpretation + deterministic goal selection** is the selected sprint scope; experimental LLM goals missed current context expiry and remain opt-in/unaccepted |
| Communication | Voice-only player path; typed/quick-call inputs are test/fallback helpers. Go/cancel fast path retains delivery/readiness checks |
| Player testimony | Fully accept valid delivered calls, including wrong calls; no credibility/history feature. Preserve explicit uncertainty and validation/physical constraints. Pinned belief behavior still needs alignment |
| Belief contract | Running scene pins Person 3 `57f809d` and the current planner's inert `trust` compatibility field. Review/test Person 3's paired field-removal changes before adopting both consumers |
| Scenario start | **Plant instant is t0.** PRX player/ally hold against retakers |
| Unknown enemies | Do not spawn guessed starts. First-known +23s arrivals: Chronicle/crashies Heaven, kaajak C Link, Boaster B Main. Remote smoke does not locate Boaster |
| Boaster adaptation | First localized by a recorded death; materialized alive at that location as a labeled authored continuation. No source kill/outcome is forced |
| Map | Default uses Person 3 seven-zone map at 76b8eaa; main was already included, map branch merged at 513b2e9. Old room/custom Lotus are explicit legacy profiles; metric fidelity remains unverified |
| Source | Person 3 annotation at `b84cc93`; event/year/title/channel/named annotator/team review unresolved. Legacy scenario filename is not verification |
| Physics | Shared movement/rifle/damage/utility/defuse; HP+armor currently one simplified pool. Annotated movement/utility baseline implemented with physical staging and evidence-based deviations; utility/continuous trajectories remain approximate |
| Human acceptance | Five standalone spoken calls confirmed. New voice-to-Lotus gameplay acceptance is unconfirmed; rendered/headless checks cannot stand in for it |
| Evidence | Exact model prompts/outputs, delayed delivery and changed decisions logged outside Git; recorded-boundary audit is scoped, not full-game fairness |
| Delivery | Offline-capable intent; OS-network-disabled, exported-build acceptance and backup video remain open |
| Deferred | Grading, debrief, belief counterfactual and evaluation comparisons; no measured training/transfer/win-rate claim |
| Schedule | Approximately six hours at final-sprint reassignment, not a freshly reset timer. Ask/check actual remaining time before planning around a deadline |
| Git | Work on `person-2/model-capability-spike`; gameplay checkpoint `608cae7`. PR #4 already merged; this branch has not been merged into main |

Free local prototype use does not erase model redistribution terms. Llama's community
license is not an unrestricted permissive license. Qwen 2.5 3B was evaluated under its
research license and is not a default dependency or a commercially cleared shipped model.
No model weights, raw audio, private logs or reference footage belong in Git.
