"""Audit actual model inputs and delivered evidence in one local voice run.

This checks the recorded boundary, not complete-game fairness or model quality.
Missing delivery records fail closed rather than assuming pre-connection evidence.
"""
import argparse
import json
from pathlib import Path
import sys


def audit(directory, source_root):
    sys.path.insert(0, str(source_root.resolve()))
    from recording.fairness_audit import audit_log
    events = [json.loads(line) for line in (directory / 'events.jsonl').read_text().splitlines()]
    models = [json.loads(line) for line in (directory / 'models.jsonl').read_text().splitlines()]
    report = audit_log(models)
    errors = list(report.errors)
    delivered = {}
    context_index = {}
    contexts = decisions = 0
    for packet in events:
        session = packet.get('session')
        if packet['type'] == 'observation':
            observation = packet['observation']
            actual = packet['delivery_tick']
            if not observation['event_tick'] <= observation['available_tick'] <= actual:
                errors.append('noncausal delivery: ' + observation['id'])
            delivered[(session, observation['bot_id'], observation['id'])] = actual
        elif packet['type'] == 'context':
            context = packet['context']
            context_index[(session, context['context_id'])] = context
            contexts += 1
            for observation in context['observations']:
                key = (session, context['bot_id'], observation['id'])
                if observation['bot_id'] != context['bot_id'] or key not in delivered or delivered[key] > context['tick']:
                    errors.append('context contains evidence not actually delivered: ' + observation['id'])
        elif packet['type'] == 'decision':
            record = packet['record']
            decisions += 1
            for evidence in record['plan'].get('decision', {}).get('evidence_ids', []):
                key = (session, record['bot_id'], evidence)
                if key not in delivered or delivered[key] > record['tick']:
                    errors.append('decision precedes actual delivery: ' + evidence)
    if not contexts or not decisions or not models:
        errors.append('incomplete run: context, decision and model records required')
    for model in models:
        if model['kind'] == 'decide':
            context = model.get('inputs', {}).get('context')
            session = model.get('extra', {}).get('session')
            if not context or context_index.get((session, context.get('context_id'))) != context:
                errors.append('model inputs do not match a recorded game context')
    return dict(ok=not errors, errors=errors, contexts=contexts,
                changed_decisions=decisions, model_records=len(models), deliveries=len(delivered))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--source-root', type=Path, required=True)
    args = parser.parse_args()
    result = audit(args.directory, args.source_root)
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result['ok'] else 1)
