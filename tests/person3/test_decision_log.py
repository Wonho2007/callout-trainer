"""
tests/person3/test_decision_log.py — decision-log fairness tests (Person 3, Step 6)
====================================================================================
Tests that the log records what the audit needs AND refuses to log a truth leak.

Run:  python -m pytest tests/person3/test_decision_log.py -q
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
if str(REPO) not in sys.path:
    sys.path.insert(0, str(REPO))

from recording import decision_log as D


GOOD_INPUTS = {
    "own_state": {"bot_id": "ally_1", "region": "b_site", "hp": 100},
    "local_beliefs": {"heaven": 0.7},
    "public_signals": {"spike_planted": True},
    "vocabulary": {"region_ids": ["b_site", "heaven"]},
}


def test_make_record_shape():
    rec = D.make_record(
        tick=42, kind="interpret", inputs=GOOD_INPUTS,
        system="sys", prompt="p", raw_output="{...}",
        parsed={"result": "report"}, source="model",
        extra={"speaker_id": "player"},
    )
    assert rec["record_version"] == D.RECORD_VERSION
    assert rec["tick"] == 42
    assert rec["kind"] == "interpret"
    assert rec["source"] == "model"
    assert rec["prompt"] == {"system": "sys", "user": "p"}
    assert rec["extra"]["speaker_id"] == "player"


@pytest.mark.parametrize("bad_key", ["truth", "scene", "enemy_transforms", "minimap", "global_truth"])
def test_forbidden_top_level_key_rejected(bad_key):
    with pytest.raises(D.LeakError):
        D.make_record(
            tick=1, kind="decide", inputs={bad_key: {"x": 1}},
            system=None, prompt=None, raw_output=None, parsed=None, source="model",
        )


def test_forbidden_nested_key_rejected():
    nested = {"own_state": {"ground_truth": {"enemy": "b_pit"}}}
    with pytest.raises(D.LeakError):
        D.make_record(tick=1, kind="decide", inputs=nested, system=None,
                      prompt=None, raw_output=None, parsed=None, source="model")


def test_negative_tick_rejected():
    with pytest.raises(ValueError):
        D.make_record(tick=-1, kind="interpret", inputs=GOOD_INPUTS, system=None,
                      prompt=None, raw_output=None, parsed=None, source="deterministic")


def test_append_and_read_roundtrip(tmp_path):
    log = D.DecisionLog(tmp_path / "dl.jsonl")
    r1 = D.make_record(tick=1, kind="interpret", inputs=GOOD_INPUTS, system="s",
                       prompt="p", raw_output="o", parsed={"result": "empty"}, source="model")
    log.append(r1)
    log.append(D.make_record(tick=2, kind="interpret", inputs=GOOD_INPUTS, system="s",
                             prompt="p", raw_output="o2", parsed={"result": "report"},
                             source="deterministic_fallback"))
    rows = log.read_all()
    assert len(rows) == 2
    assert rows[0]["tick"] == 1 and rows[1]["source"] == "deterministic_fallback"


def test_log_interpret_from_interpreter_result(tmp_path):
    # shape returned by comms.interpreter.interpret()
    result = {"result": "report", "source": "model",
              "proposal": {"kind": "report", "payload": {"action": "report_enemy",
                           "region_id": "heaven", "count": 2, "hedge": "sure"}},
              "raw": '{"...": true}', "transcript": "two heaven"}
    log = D.DecisionLog(tmp_path / "dl.jsonl")
    rec = log.log_interpret(tick=7, inputs=GOOD_INPUTS, result=result,
                            system="sys", prompt="pr")
    assert rec["raw_output"] == '{"...": true}'
    assert rec["parsed"]["result"] == "report"
    assert "raw" not in rec["parsed"]  # raw is split out into raw_output
    assert log.read_all()[0]["tick"] == 7
