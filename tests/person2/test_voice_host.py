"""Model boundary checks: unavailable/foreign evidence and authored target limits."""
import importlib.util
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'bots'))
spec = importlib.util.spec_from_file_location('voice_host', ROOT / 'bots/voice_host.py')
host = importlib.util.module_from_spec(spec)
spec.loader.exec_module(host)


def fixture():
    return ({'tick': 20, 'observations': [{'id': 'seen', 'available_tick': 20},
                                      {'id': 'future', 'available_tick': 21}],
             'own_state': {'reachable_marker_ids': ['cover']}}, {'cover': ['room']},
            {'goal': 'cover', 'target_id': 'cover', 'watch_region_id': 'room', 'evidence_ids': ['seen']})


def test_actual_available_evidence_and_authored_target():
    context, markers, candidate = fixture()
    assert host.validate_goal(candidate, context, markers) == candidate


def test_reject_future_foreign_duplicate_evidence_and_hidden_targets():
    import pytest
    context, markers, candidate = fixture()
    for change in ({'evidence_ids': ['future']}, {'evidence_ids': ['other_bot']},
                   {'evidence_ids': ['seen', 'seen']}, {'target_id': 'enemy_position'},
                   {'watch_region_id': 'hidden_region'}, {'goal': 'shoot'},
                   {'coordinates': [1, 2, 3]}, {'target_id': ['not', 'text']}):
        with pytest.raises(ValueError):
            host.validate_goal(dict(candidate, **change), context, markers)


def test_stop_cannot_smuggle_target():
    import pytest
    context, markers, candidate = fixture()
    with pytest.raises(ValueError):
        host.validate_goal(dict(candidate, goal='stop'), context, markers)
    assert host.validate_goal(dict(candidate, goal='stop', target_id=None, watch_region_id=None), context, markers)


def test_disconnected_idle_host_never_opens_microphone(monkeypatch):
    import threading
    from types import SimpleNamespace
    closed = threading.Event()
    closed.set()
    monkeypatch.setitem(sys.modules, 'keyboard', SimpleNamespace(is_pressed=lambda key: False))
    def unexpected_stream(**kwargs):
        raise AssertionError('microphone opened after disconnect')
    monkeypatch.setitem(sys.modules, 'sounddevice', SimpleNamespace(InputStream=unexpected_stream))
    assert host.capture_for_game(SimpleNamespace(closed=closed)) is None
