"""Authoring checks specific to the first-known-position adaptation.

Person 3's validator owns scenario.v1 structural checks. These extra checks bind
that scenario to the runtime schedule and authored geometry without guessing starts.
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGIONS = {'b_main', 'b_cubby', 'b_heaven', 'b_upper', 'b_pit', 'c_link', 'a_link'}


def validate(scenario, runtime, map_data):
    errors = []
    region_map = {r['id']: r for r in map_data['regions']}
    if set(region_map) != REGIONS or set(runtime['planner']['regions']) != REGIONS:
        errors.append('world/runtime must use the seven frozen region IDs')
    actors = {a['id']: a for a in scenario['actors']}
    first_known = {}
    for beat in scenario['timeline']:
        if beat['action'] == 'first_known_position':
            first_known.setdefault(beat['actor_id'], beat)
    scheduled = set()
    for entry in runtime['spawn_schedule']:
        actor_id = entry['actor_id']
        if actor_id in scheduled:
            errors.append('duplicate arrival: ' + actor_id)
        scheduled.add(actor_id)
        if actors.get(actor_id, {}).get('start_region') != 'unknown':
            errors.append('unknown-at-plant actor must retain unknown start: ' + actor_id)
        beat = first_known.get(actor_id)
        if not beat or entry['first_known_tick'] != beat['tick'] or entry['region_id'] != beat['region']:
            errors.append('arrival does not match first known annotation beat: ' + actor_id)
        if entry['first_known_tick'] <= 0:
            errors.append('unknown enemy cannot spawn at plant: ' + actor_id)
        contained = []
        for region in region_map.values():
            point = [entry['position'][0], entry['position'][1] + 0.9, entry['position'][2]]
            if all(abs(point[i] - region['center'][i]) <= region['size'][i] / 2 for i in range(3)):
                contained.append(region['id'])
        if contained != [entry['region_id']]:
            errors.append('arrival physical coordinate is outside its unique named region: ' + actor_id)
    if scheduled != set(runtime['enemy_ids']) or scheduled != set(first_known):
        errors.append('first-known actors, runtime slots and scheduled arrivals differ')
    if any(spawn['role'] != 'player' for spawn in map_data['spawns']):
        errors.append('map must not pre-place unknown enemies')
    regions = list(region_map.values())
    for index, a in enumerate(regions):
        for b in regions[index + 1:]:
            if all(abs(a['center'][i] - b['center'][i]) < (a['size'][i] + b['size'][i]) / 2 - 1e-6 for i in range(3)):
                errors.append('ambiguous overlapping region interiors: ' + a['id'] + '/' + b['id'])
    if runtime.get('start_at') != 'spike_plant' or not scenario['round_context']['spike_planted']:
        errors.append('scenario must begin at plant')
    return errors


def validate_files():
    load = lambda path: json.loads((ROOT / path).read_text())
    return validate(load('scenarios/fnc_prx_lotus_toronto2024_gf.json'),
                    load('scenarios/lotus_b_coverage.json'), load('world/maps/lotus_b_adaptation.json'))


if __name__ == '__main__':
    argparse.ArgumentParser(__doc__).parse_args()
    errors = validate_files()
    print('\n'.join(errors) if errors else 'PASS: plant start, unknown preservation, first-known spawn timing and seven unique regions')
    raise SystemExit(bool(errors))
