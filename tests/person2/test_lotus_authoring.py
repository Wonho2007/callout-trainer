import copy
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'validation'))
from check_lotus import validate, validate_files


def fixture():
    return [json.loads((ROOT / p).read_text()) for p in
            ['scenarios/fnc_prx_lotus_toronto2024_gf.json', 'scenarios/lotus_b_coverage.json', 'world/maps/lotus_b_adaptation.json']]


def test_committed_data_preserves_first_known_positions():
    assert validate_files() == []


def test_remote_utility_does_not_allow_early_boaster_spawn():
    scenario, runtime, map_data = fixture()
    next(x for x in runtime['spawn_schedule'] if x['actor_id'] == 'boaster')['first_known_tick'] = 960
    assert any('first known' in error for error in validate(scenario, runtime, map_data))


def test_guessed_start_duplicate_or_wrong_region_rejected():
    scenario, runtime, map_data = fixture()
    for change in ('guessed_start', 'duplicate', 'wrong_region'):
        source, live, world = copy.deepcopy((scenario, runtime, map_data))
        if change == 'guessed_start':
            next(a for a in source['actors'] if a['id'] == 'boaster')['start_region'] = 'b_main'
        elif change == 'duplicate':
            live['spawn_schedule'].append(live['spawn_schedule'][0])
        else:
            live['spawn_schedule'][0]['position'] = [0, 0, 9]
        assert validate(source, live, world)
