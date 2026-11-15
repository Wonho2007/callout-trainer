"""
tests/person3/test_fairness_audit.py — leak test / fairness audit (Person 3, final sprint §3)
==============================================================================================
Pure logic, no engine. Proves fairness against the RECORDED decision log, not by replay:
  (a) every cited evidence id existed and was available by the decision tick,
  (b) no forbidden/truth key appears in any logged inputs,
  (c) perturbing unseen hidden state leaves the allowed inputs -> allowed output unchanged.

Run:  python -m pytest tests/person3/test_fairness_audit.py -q
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
if str(REPO) not in sys.path:
    sys.path.insert(0, str(REPO))

from comms import vocabulary as V
from comms.pipeline import CommsPipeline, PipelineConfig
from recording.decision_log import DecisionLog
from recording.fairness_audit import audit_log, perturbation_invariant

REGION = V.REGION_IDS[0]
ALIAS_WORD = next(w for w, r in V.REGION_ALIASES.items() if r == REGION)


def _run_sample(tmp_path):
    """Produce a real decision log + observation stream from the pipeline."""
    log = DecisionLog(tmp_path / "dl.jsonl")
    cfg = PipelineConfig(bot_id="omen_bot", region_ids=list(V.REGION_IDS), enemy_ids=["e1"])
    p = CommsPipeline(cfg, log=log)
    observations = []
    for i, text in enumerate([f"two {ALIAS_WORD}", "flash that smoke", f"one {ALIAS_WORD}"]):
        out = p.handle_text(text, timestamp_s=float(i + 1))
        if "observation" in out:
            observations.append(out["observation"])
    return log.read_all(), observations


# --- (a) availability + (b) no-leak on a clean log --------------------------

def test_clean_log_passes_audit(tmp_path):
    records, observations = _run_sample(tmp_path)
    report = audit_log(records, observations=observations)
    assert report.ok, report.errors
    assert report.checked == len(records)


def test_forbidden_key_in_inputs_is_caught(tmp_path):
    records, observations = _run_sample(tmp_path)
    # simulate a leak: inject a truth key into one record's inputs
    records[0]["inputs"]["own_state"]["ground_truth"] = {"enemy": REGION}
    report = audit_log(records, observations=observations)
    assert not report.ok
    assert any("ground_truth" in e for e in report.errors)


def test_future_evidence_is_caught():
    # a decision at tick 5 cites an observation only available at tick 9 -> fail
    records = [{
        "record_version": "decision_log.v1", "tick": 5, "kind": "interpret",
        "source": "model", "inputs": {}, "prompt": {}, "raw_output": None,
        "parsed": {}, "evidence_ids": ["o_future"],
        "extra": {"recipient_id": "bot"},
    }]
    observations = [{"id": "o_future", "bot_id": "bot", "event_tick": 0, "available_tick": 9}]
    report = audit_log(records, observations=observations)
    assert not report.ok
    assert any("future evidence" in e for e in report.errors)


def test_foreign_evidence_is_caught():
    records = [{
        "record_version": "decision_log.v1", "tick": 5, "kind": "interpret",
        "source": "model", "inputs": {}, "prompt": {}, "raw_output": None,
        "parsed": {}, "evidence_ids": ["o_other_bot"],
        "extra": {"recipient_id": "bot_A"},
    }]
    observations = [{"id": "o_other_bot", "bot_id": "bot_B", "event_tick": 0, "available_tick": 1}]
    report = audit_log(records, observations=observations)
    assert not report.ok
    assert any("not an observation for bot" in e for e in report.errors)


# --- (c) perturbation: unseen enemy movement cannot change the decision -----

def test_perturbation_unseen_enemy_movement_is_invariant(tmp_path):
    cfg = PipelineConfig(bot_id="omen_bot", region_ids=list(V.REGION_IDS), enemy_ids=["e1"])
    p = CommsPipeline(cfg)

    allowed = {
        "transcript": f"two {ALIAS_WORD}",
        "vocabulary": {"region_ids": list(V.REGION_IDS)},
        "local_belief_snapshot": p.belief.snapshot(),
        "own_state": {"bot_id": "omen_bot"},
    }

    def run_once(inputs):
        # decision depends ONLY on the allowed inputs (the transcript here)
        fresh = CommsPipeline(PipelineConfig(bot_id="omen_bot",
                              region_ids=list(V.REGION_IDS), enemy_ids=["e1"]))
        out = fresh.handle_text(inputs["transcript"], timestamp_s=1.0)
        return out["message"]["payload"]  # the allowed output

    # the world moves an unseen enemy to different regions — passed NOWHERE
    hidden_variants = [{"enemy_truth": {"e1": r}} for r in V.REGION_IDS]
    report = perturbation_invariant(run_once, allowed, hidden_variants)
    assert report.ok, report.errors


def test_perturbation_flags_a_leaky_decision():
    # a deliberately-broken decision fn that peeks at hidden state -> audit catches it
    allowed = {"vocabulary": {"region_ids": ["r1", "r2"]}}
    leaked_state = {"n": 0}

    def leaky(inputs):
        # BUG on purpose: output depends on a mutable external (stands in for hidden truth)
        leaked_state["n"] += 1
        return {"region_id": "r1" if leaked_state["n"] % 2 else "r2"}

    report = perturbation_invariant(leaky, allowed, [{"x": 1}, {"x": 2}])
    assert not report.ok
