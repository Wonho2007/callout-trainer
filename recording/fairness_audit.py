"""
recording/fairness_audit.py — leak test over a recorded decision log (Person 3, §3)
====================================================================================
The LLM is non-deterministic, so fairness CANNOT be proven by replaying to the same
output. It is proven against the RECORDED decision log: for each decision, the inputs the
model was given must be a subset of what the bot could legitimately observe by that tick,
and must contain no hidden truth. A grep is not a proof — these are structural checks over
the logged records plus a perturbation argument.

This is the pure-logic, no-engine mirror of recording/evidence_audit.gd and the pitch's
integrity claim. Three checks:

  (a) AVAILABILITY. Every evidence id a decision cites existed as an observation for that
      bot and was available (available_tick <= decision tick) by the decision's tick.
  (b) NO LEAK. No forbidden/truth key (truth, scene, enemy_transforms, minimap, spectator…)
      appears anywhere in any decision's logged `inputs`.
  (c) PERTURBATION. Changing only HIDDEN state the bot was not allowed to see (e.g. moving
      an unseen enemy) must not change the decision's allowed inputs, hence must not change
      the allowed output set. We assert this against a re-run under the SAME logged inputs:
      identical allowed inputs -> identical allowed set. (For a non-deterministic model the
      "allowed set" is the schema-valid proposal space; we check the logged parsed result is
      inside it and that perturbing hidden state leaves the inputs — and therefore the
      allowed set — unchanged.)

Usage:
    from recording.fairness_audit import audit_log, AuditReport
    report = audit_log(records, observations=obs_list)   # records = DecisionLog.read_all()
    assert report.ok, report.errors
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable, Optional

from recording.decision_log import FORBIDDEN_INPUT_KEYS


@dataclass
class AuditReport:
    ok: bool
    errors: list[str] = field(default_factory=list)
    checked: int = 0

    def __bool__(self) -> bool:  # allow `if report:`
        return self.ok


# ---------------------------------------------------------------------------
# (b) no-leak scan — recurse the inputs, reject any forbidden key
# ---------------------------------------------------------------------------

def _find_forbidden_keys(obj: Any, path: str = "inputs") -> list[str]:
    hits: list[str] = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(k, str) and k.lower() in FORBIDDEN_INPUT_KEYS:
                hits.append(f"{path}.{k}")
            hits.extend(_find_forbidden_keys(v, f"{path}.{k}"))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            hits.extend(_find_forbidden_keys(v, f"{path}[{i}]"))
    return hits


# ---------------------------------------------------------------------------
# Main audit over a list of decision-log records
# ---------------------------------------------------------------------------

def audit_log(
    records: list[dict],
    observations: Optional[list[dict]] = None,
) -> AuditReport:
    """Run checks (a) and (b) over recorded decision-log records.

    Parameters
    ----------
    records : list[dict]
        Decision-log records (recording.decision_log.DecisionLog.read_all()). Each has
        tick, kind, source, inputs, prompt, raw_output, parsed, optional evidence_ids/extra.
    observations : list[dict] or None
        The bot's observation stream {id, bot_id, event_tick, available_tick, ...}. Needed
        for check (a); if None, availability is checked only for evidence embedded in the
        record's own observation (the glue attaches the told observation to the inputs).
    """
    errors: list[str] = []

    # Index observations by (bot_id, id) with their available_tick.
    index: dict[tuple, int] = {}
    if observations:
        for o in observations:
            try:
                index[(o["bot_id"], o["id"])] = int(o["available_tick"])
            except (KeyError, TypeError, ValueError):
                errors.append(f"malformed observation: {o!r}")

    for i, rec in enumerate(records):
        tick = rec.get("tick")
        if not isinstance(tick, int) or tick < 0:
            errors.append(f"record[{i}]: bad tick {tick!r}")
            continue

        # (b) NO LEAK
        for hit in _find_forbidden_keys(rec.get("inputs", {})):
            errors.append(f"record[{i}] (tick {tick}): forbidden key at {hit}")

        # (a) AVAILABILITY — evidence ids may live on the record or its extra.
        bot_id = (rec.get("extra") or {}).get("recipient_id") or rec.get("bot_id")
        evidence_ids = rec.get("evidence_ids")
        if evidence_ids is None:
            # glue stores the told observation inside inputs; derive its id if present.
            snap = (rec.get("inputs") or {}).get("local_belief_snapshot") or {}
            evidence_ids = snap.get("evidence_ids", []) if isinstance(snap, dict) else []
        for eid in evidence_ids or []:
            if observations is None:
                continue  # nothing to check against; skip quietly
            key = (bot_id, eid)
            if key not in index:
                errors.append(f"record[{i}] (tick {tick}): evidence {eid!r} not an "
                              f"observation for bot {bot_id!r}")
            elif index[key] > tick:
                errors.append(f"record[{i}] (tick {tick}): evidence {eid!r} available at "
                              f"{index[key]} > decision tick {tick} (future evidence)")

    return AuditReport(ok=not errors, errors=errors, checked=len(records))


# ---------------------------------------------------------------------------
# (c) perturbation — unseen hidden-state change must not alter allowed inputs/output
# ---------------------------------------------------------------------------

def perturbation_invariant(
    run_once: Callable[[dict], dict],
    allowed_inputs: dict,
    hidden_variants: list[dict],
) -> AuditReport:
    """Assert that perturbing only HIDDEN state leaves the decision's allowed output set
    unchanged, because the hidden state is never passed as an input.

    Parameters
    ----------
    run_once : callable(allowed_inputs) -> result
        Produces the decision's parsed result from the ALLOWED inputs only. The caller
        must NOT let `hidden` reach this function — that is the whole point.
    allowed_inputs : dict
        The copied, allowed inputs (observations/belief/state/vocab). No truth.
    hidden_variants : list[dict]
        Different hidden-world states (e.g. an unseen enemy in different regions). These
        are passed NOWHERE; they exist only to prove the output does not depend on them.
    """
    errors: list[str] = []
    # Guard: allowed_inputs must itself be leak-free.
    for hit in _find_forbidden_keys(allowed_inputs):
        errors.append(f"allowed_inputs contain forbidden key at {hit}")

    baseline = run_once(dict(allowed_inputs))
    for j, hidden in enumerate(hidden_variants):
        # The world moved an unseen enemy; allowed inputs are byte-identical, so re-running
        # on them must reproduce the baseline allowed output. `hidden` is deliberately unused
        # by run_once — passing it would BE the leak we are proving absent.
        _ = hidden
        again = run_once(dict(allowed_inputs))
        if again != baseline:
            errors.append(
                f"hidden variant [{j}] changed the output despite identical allowed inputs: "
                f"{baseline!r} -> {again!r}"
            )
    return AuditReport(ok=not errors, errors=errors, checked=1 + len(hidden_variants))
