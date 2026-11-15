"""Measure an unchanged Person 3 interpreter snapshot against local Ollama.

No third-party Python dependencies. Records exact prompts, outputs, semantic checks
and Ollama token timings; fallback is never counted as successful model output.
"""
import argparse
import json
import statistics
import sys
import time
import urllib.request
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--model', default='llama3.1:8b')
    parser.add_argument('--host', default='http://127.0.0.1:11434')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str(args.source_root.resolve()))
    from comms import interpreter as I, vocabulary as V

    class MeasuredClient(I.OllamaClient):
        def generate(self, system, prompt):
            body = dict(model=self.model, system=system, prompt=prompt,
                        stream=False, options={'temperature': 0.0}, format='json')
            request = urllib.request.Request(self.host + '/api/generate',
                data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
            with urllib.request.urlopen(request, timeout=60) as response:
                self.metrics = json.load(response)
            return self.metrics.get('response', '')

    cases = [
        ('two on heaven', 'report', dict(region_id='b_heaven', count=2, hedge='sure')),
        ("i think someone's b main", 'report', dict(region_id='b_main', count=None, hedge='think')),
        ('maybe one in pit', 'report', dict(region_id='b_pit', count=1, hedge='unsure')),
        ('flash heaven on my cue', 'command', dict(action='throw_flash', target_id='b_heaven', timing={'mode': 'on_cue'})),
        ('swing main with me', 'command', dict(action='swing_together', target_id='b_main', timing={'mode': 'follow_player'})),
        ('flash that smoke', 'clarify', {}),
        ('go plant the spike', 'unsupported', {}),
        ("they're pushing b main three of them", 'report', dict(region_id='b_main', count=3, hedge='sure')),
    ]
    vocab = V.build_vocabulary(scenario_agents=['Yoru', 'Omen'])
    client = MeasuredClient(args.model, host=args.host)
    records = []

    def run(transcript, expected=None, fields=None, cold=False):
        client.metrics = {}
        logs = []
        start = time.perf_counter()
        result = I.interpret(transcript, vocab, client, on_log=logs.append)
        elapsed = time.perf_counter() - start
        payload = result.get('proposal', {}).get('payload', {})
        correct = expected is not None and result.get('source') == 'model' and result.get('result') == expected and all(payload.get(k) == v for k, v in (fields or {}).items())
        metrics = {k: client.metrics.get(k) for k in ('total_duration', 'load_duration', 'prompt_eval_count', 'prompt_eval_duration', 'eval_count', 'eval_duration', 'done_reason')}
        duration = metrics.get('eval_duration') or 0
        row = dict(transcript=transcript, cold=cold, elapsed_s=elapsed,
                   semantic_correct=correct, result=result, log=logs, metrics=metrics,
                   tokens_per_s=(metrics['eval_count'] * 1e9 / duration) if duration else None)
        records.append(row)
        print(json.dumps({k: row[k] for k in ('transcript', 'cold', 'elapsed_s', 'semantic_correct', 'tokens_per_s')}), flush=True)

    run(cases[0][0], cold=True)
    for transcript, expected, fields in cases:
        run(transcript, expected, fields)
    warm = records[1:]
    summary = dict(model=args.model, host=args.host, source_root=str(args.source_root),
        warm_median_s=statistics.median(r['elapsed_s'] for r in warm),
        semantic_correct=sum(r['semantic_correct'] for r in warm), cases=len(warm),
        valid_model_outputs=sum(r['result']['source'] == 'model' for r in warm),
        fallback_count=sum(r['result']['source'] == 'deterministic_fallback' for r in warm))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(dict(summary=summary, records=records), indent=2), encoding='utf-8')
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == '__main__':
    main()
