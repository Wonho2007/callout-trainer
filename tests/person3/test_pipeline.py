"""
tests/person3/test_pipeline.py — transcript->belief glue tests (Person 3, final sprint §1/§2)
==============================================================================================
Headless, offline, no GPU/engine. Covers every branch the sprint lists (valid report,
clarify, unsupported, model-illegal -> deterministic fallback), the reaction-delay told
observation, the belief snapshot shape Person 2 consumes, the belief math matching
belief/region_belief.gd, and that EVERY path writes exactly one decision-log record.

Run:  python -m pytest tests/person3/test_pipeline.py -q
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
if str(REPO) not in sys.path:
    sys.path.insert(0, str(REPO))

from comms import interpreter as I
from comms import vocabulary as V
from comms.pipeline import CommsPipeline, PipelineConfig, ReportBelief, Transcript, HEDGE_STRENGTH
from recording.decision_log import DecisionLog

REGION = V.REGION_IDS[0]  # a real frozen id, whatever it is
ALIAS_WORD = next(w for w, r in V.REGION_ALIASES.items() if r == REGION)  # a spoken form of it


class Echo:
    def __init__(self, text): self.text = text
    def generate(self, system, prompt): return self.text


class Broken:
    def generate(self, system, prompt): raise ConnectionError("no runtime")


def _cfg(tmp_path=None):
    return PipelineConfig(bot_id="omen_bot", speaker_id="player",
                          region_ids=list(V.REGION_IDS), enemy_ids=["e1", "e2"])


# --- belief mirror matches region_belief.gd math ----------------------------

def test_belief_prior_is_uniform():
    b = ReportBelief("bot", list(V.REGION_IDS), ["e1"])
    snap = b.snapshot()
    n = len(V.REGION_IDS)
    for r, p in snap["enemies"]["e1"].items():
        assert abs(p - 1.0 / n) < 1e-12


def test_belief_report_shifts_mass_to_called_region():
    regions = list(V.REGION_IDS)
    b = ReportBelief("bot", regions, ["e1"])
    n = len(regions)
    # hand-build the same update region_belief.gd._report does for hedge "sure"
    strength = HEDGE_STRENGTH["sure"]
    msg = {"schema_version": "comms.v1", "message_id": "m1", "speaker_id": "player",
           "recipient_id": "bot", "issued_tick": 0, "expires_tick": 100, "kind": "report",
           "payload": {"action": "report_enemy", "region_id": regions[0], "count": 2, "hedge": "sure"}}
    obs = {"id": "o1", "bot_id": "bot", "event_tick": 0, "available_tick": 5,
           "source": "told", "speaker_id": "player", "content": {"type": "comms", "message": msg}}
    assert b.apply(obs, 5)["ok"]
    post = b.snapshot()["enemies"]["e1"]
    # independent re-derivation of the single Bayesian step
    like = {c: (strength if c == regions[0] else 0.0) + (1 - strength) / n for c in regions}
    expect = {c: (1.0 / n) * like[c] for c in regions}
    z = sum(expect.values())
    expect = {c: v / z for c, v in expect.items()}
    for c in regions:
        assert abs(post[c] - expect[c]) < 1e-12
    assert post[regions[0]] == max(post.values())


# --- pipeline branches ------------------------------------------------------

def test_valid_report_updates_belief_and_snapshot():
    p = CommsPipeline(_cfg())
    out = p.handle_text(f"two {ALIAS_WORD}", timestamp_s=1.0)
    assert out["result"] == "report"
    assert out["applied"] is True
    assert out["message"]["payload"]["region_id"] == REGION
    # reaction delay applied: available_tick > issued_tick
    assert out["observation"]["available_tick"] > out["observation"]["event_tick"]
    snap = out["snapshot"]
    assert set(snap.keys()) == {"bot_id", "tick", "enemies", "evidence_ids"}
    assert snap["enemies"]["e1"][REGION] == max(snap["enemies"]["e1"].values())


def test_clarify_does_not_touch_belief():
    p = CommsPipeline(_cfg())
    out = p.handle_text("flash that smoke")
    assert out["result"] == "clarify"
    assert out["applied"] is False
    assert "snapshot" not in out


def test_unsupported_does_not_touch_belief():
    p = CommsPipeline(_cfg())
    out = p.handle_text("go plant the spike")
    assert out["result"] == "unsupported"
    assert out["applied"] is False


def test_command_is_interpreted_not_applied_to_belief():
    p = CommsPipeline(_cfg())
    out = p.handle_text(f"flash {ALIAS_WORD}")
    assert out["result"] == "command"
    assert out["applied"] is False  # commands are intents for the executor, not sightings


def test_model_illegal_region_falls_back_to_deterministic():
    # model invents a region -> validation fails -> circuit breaker -> deterministic
    client = Echo('{"result":"report","payload":{"action":"report_enemy","region_id":"not_a_region","count":1,"hedge":"sure"}}')
    p = CommsPipeline(_cfg(), client=client)
    out = p.handle_text(f"one {ALIAS_WORD}")
    assert out["source"] == "deterministic_fallback"
    assert out["result"] == "report"
    assert out["message"]["payload"]["region_id"] == REGION


def test_broken_client_trips_breaker_and_still_updates():
    p = CommsPipeline(_cfg(), client=Broken())
    out = p.handle_text(f"two {ALIAS_WORD}")
    assert out["source"] == "deterministic_fallback"
    assert out["applied"] is True


def test_valid_model_output_used_directly():
    client = Echo(f'{{"result":"report","payload":{{"action":"report_enemy","region_id":"{REGION}","count":3,"hedge":"think"}}}}')
    p = CommsPipeline(_cfg(), client=client)
    out = p.handle_text("whatever")
    assert out["source"] == "model"
    assert out["message"]["payload"] == {"action": "report_enemy", "region_id": REGION, "count": 3, "hedge": "think"}


# --- decision-log wiring: every path logs exactly once ----------------------

@pytest.mark.parametrize("text,expect", [
    (f"two {ALIAS_WORD}", "report"),
    ("flash that smoke", "clarify"),
    ("go plant the spike", "unsupported"),
    (f"flash {ALIAS_WORD}", "command"),
])
def test_every_path_writes_one_log_record(tmp_path, text, expect):
    log = DecisionLog(tmp_path / "dl.jsonl")
    p = CommsPipeline(_cfg(), log=log)
    out = p.handle_text(text, timestamp_s=2.0)
    assert out["result"] == expect
    rows = log.read_all()
    assert len(rows) == 1
    r = rows[0]
    assert r["kind"] == "interpret"
    assert r["tick"] == int(round(2.0 * p.cfg.tick_rate_hz))
    assert r["source"] in ("deterministic", "model", "deterministic_fallback")
    assert r["inputs"]["transcript"] == text
    # no truth keys ever reach the log inputs
    assert "truth" not in str(r["inputs"]).lower()


def test_from_stt_handoff_shape():
    # the live-mic path: voice.stt.transcribe() returns (text, latency); from_stt adapts it
    t = Transcript.from_stt("two " + ALIAS_WORD, latency_s=0.4, started_s=3.0)
    assert t.text.endswith(ALIAS_WORD)
    assert t.timestamp_s == 3.0  # anchored to utterance start, not STT finish
    p = CommsPipeline(_cfg())
    out = p.handle(t)
    assert out["result"] == "report"
    assert out["message"]["issued_tick"] == int(round(3.0 * p.cfg.tick_rate_hz))
