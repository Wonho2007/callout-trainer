"""
tests/person3/test_interpreter.py — interpreter wrapper tests (Person 3, Step 5.2)
===================================================================================
Tests the WRAPPER, not the model's creativity: parse + vocabulary/contract validation,
the deterministic circuit-breaker fallback, clarify/unsupported handling, and the
"never infer 1 from someone" rule. Fully offline; uses stub model clients.

Run:  python -m pytest tests/person3/test_interpreter.py -q
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


@pytest.fixture
def vocab():
    return V.build_vocabulary(scenario_agents=["Omen", "Raze"])


# --- stub clients -----------------------------------------------------------

class EchoClient:
    """Returns a fixed string regardless of prompt (simulates a cooperative model)."""
    def __init__(self, text: str):
        self.text = text
    def generate(self, system, prompt):
        return self.text


class BrokenClient:
    """Always raises — simulates offline runtime / timeout (trips the breaker)."""
    def generate(self, system, prompt):
        raise ConnectionError("ollama not running")


# --- deterministic path -----------------------------------------------------

def test_deterministic_report_with_count_and_hedge(vocab):
    r = I.interpret("two on heaven", vocab)  # no client -> deterministic
    assert r["result"] == "report"
    p = r["proposal"]["payload"]
    assert p == {"action": "report_enemy", "region_id": "b_heaven", "count": 2, "hedge": "sure"}
    assert r["source"] == "deterministic"


def test_deterministic_think_hedge(vocab):
    r = I.interpret("i think someone's b main", vocab)
    assert r["result"] == "report"
    assert r["proposal"]["payload"]["region_id"] == "b_main"
    assert r["proposal"]["payload"]["hedge"] == "think"


def test_never_infer_one_from_someone(vocab):
    r = I.interpret("someone in pit", vocab)
    assert r["result"] == "report"
    assert r["proposal"]["payload"]["count"] is None  # NOT 1


def test_swing_with_me_is_follow_player(vocab):
    r = I.interpret("swing main with me", vocab)
    assert r["result"] == "command"
    p = r["proposal"]["payload"]
    assert p["action"] == "swing_together"
    assert p["target_id"] == "b_main"
    assert p["timing"]["mode"] == "follow_player"


def test_flash_on_cue(vocab):
    r = I.interpret("flash heaven on my cue", vocab)
    assert r["result"] == "command"
    p = r["proposal"]["payload"]
    assert p["action"] == "throw_flash"
    assert p["timing"]["mode"] == "on_cue"


def test_flash_without_region_clarifies(vocab):
    r = I.interpret("flash it", vocab)
    assert r["result"] == "clarify"


def test_unsupported_action(vocab):
    r = I.interpret("go plant the spike", vocab)
    assert r["result"] == "unsupported"


def test_unknown_region_clarifies_not_guesses(vocab):
    r = I.interpret("they're in the kitchen", vocab)
    assert r["result"] == "clarify"


def test_empty_transcript(vocab):
    r = I.interpret("   ", vocab)
    assert r["result"] == "empty"


# --- model path + validation ------------------------------------------------

def test_model_valid_output_accepted(vocab):
    client = EchoClient('{"result":"report","payload":{"action":"report_enemy","region_id":"b_main","count":3,"hedge":"think"}}')
    r = I.interpret("three b main i think", vocab, client)
    assert r["source"] == "model"
    assert r["proposal"]["payload"] == {"action": "report_enemy", "region_id": "b_main", "count": 3, "hedge": "think"}
    assert r["raw"]  # raw model text preserved for logging


def test_model_output_with_markdown_fence_parsed(vocab):
    client = EchoClient('```json\n{"result":"empty","reason":"silence"}\n```')
    r = I.interpret("...", vocab, client)
    assert r["result"] == "empty"
    assert r["source"] == "model"


def test_model_illegal_region_falls_back(vocab):
    # model invents a region not in the vocabulary -> validation fails -> breaker
    client = EchoClient('{"result":"report","payload":{"action":"report_enemy","region_id":"a_rafters","count":1,"hedge":"sure"}}')
    r = I.interpret("one heaven", vocab, client)
    assert r["source"] == "deterministic_fallback"
    assert r["result"] == "report"
    assert r["proposal"]["payload"]["region_id"] == "b_heaven"  # fallback resolved it


def test_model_count_zero_is_illegal_falls_back(vocab):
    client = EchoClient('{"result":"report","payload":{"action":"report_enemy","region_id":"b_heaven","count":0,"hedge":"sure"}}')
    r = I.interpret("heaven", vocab, client)
    assert r["source"] == "deterministic_fallback"


def test_model_junk_output_falls_back(vocab):
    client = EchoClient("I think they are pushing B, be careful!")  # prose, no JSON
    r = I.interpret("they're b main", vocab, client)
    assert r["source"] == "deterministic_fallback"
    assert r["result"] == "report"


def test_broken_client_trips_circuit_breaker(vocab):
    r = I.interpret("two heaven", vocab, BrokenClient())
    assert r["source"] == "deterministic_fallback"
    assert r["result"] == "report"
    assert r["proposal"]["payload"]["count"] == 2
    assert "<model error:" in r["raw"]


def test_illegal_command_timing_falls_back(vocab):
    # throw_flash does not allow follow_player -> illegal -> breaker
    client = EchoClient('{"result":"command","payload":{"action":"throw_flash","target_id":"b_heaven","timing":{"mode":"follow_player"}}}')
    r = I.interpret("flash heaven", vocab, client)
    assert r["source"] == "deterministic_fallback"


def test_on_log_callback_receives_record(vocab):
    captured = []
    I.interpret("two heaven", vocab, EchoClient('{"result":"report","payload":{"action":"report_enemy","region_id":"b_heaven","count":2,"hedge":"sure"}}'),
                on_log=captured.append)
    assert len(captured) == 1
    rec = captured[0]
    assert rec["source"] == "model"
    assert "prompt" in rec and "raw" in rec and "parsed" in rec
