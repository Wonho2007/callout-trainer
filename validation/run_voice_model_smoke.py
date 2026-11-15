"""Run the real local LLM -> TCP -> Godot delivery/goal/physics fixture.

Uses a clearly labelled typed transcript injection, not a human/microphone claim.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--goal-model', default='qwen2.5:3b')
    parser.add_argument('--interpret-only', action='store_true', help='Validate the sprint fallback scope; full goal test stays separate')
    args = parser.parse_args()
    sys.path.insert(0, str(ROOT / 'bots'))
    from voice_host import warm_model
    print('Preloading local model before the test round...', flush=True)
    warm_model('http://127.0.0.1:11434', 'llama3.1:8b')
    if not args.interpret_only:
        warm_model('http://127.0.0.1:11434', args.goal_model)
    output = ROOT / 'runs' / ('voice-model-' + time.strftime('%Y%m%d-%H%M%S'))
    output.mkdir(parents=True, exist_ok=True)
    command = [sys.executable, '-u', 'validation/run_person2_tests.py', '--godot', args.godot,
               '--voice-playtest', '--voice-headless', '--voice-port', '0',
               '--person1-ref', '8712f7d', '--person3-ref', '57f809d']
    if args.interpret_only:
        command.append('--voice-interpret-only')
    game = host = None
    try:
        with (output / 'game.log').open('w', encoding='utf-8') as log:
            game = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 35
            port = None
            while time.monotonic() < deadline:
                content = (output / 'game.log').read_text(encoding='utf-8')
                match = re.search(r'PERSON2_VOICE_READY port=(\d+)', content)
                if match:
                    port = match.group(1)
                    break
                if game.poll() is not None:
                    raise RuntimeError('Game stopped before voice readiness: ' + content)
                time.sleep(0.1)
            if port is None:
                raise RuntimeError('No voice bridge readiness')
            with (output / 'host.log').open('w', encoding='utf-8') as host_log:
                host = subprocess.Popen([sys.executable, '-u', 'bots/voice_host.py', '--source-root', str(args.source_root),
                    '--port', port, '--text', 'one enemy in room', '--seconds', '14', '--output', str(output), '--goal-model', args.goal_model,
                    *([] if args.interpret_only else ['--model-goals'])],
                    cwd=ROOT, stdout=host_log, stderr=subprocess.STDOUT)
                host_code = host.wait(timeout=25)
                game_code = game.wait(timeout=20)
        content = (output / 'game.log').read_text(encoding='utf-8')
        print(content)
        print((output / 'host.log').read_text(encoding='utf-8'))
        print('Exact model and engine records:', output)
        records = [json.loads(line) for line in (output / 'models.jsonl').read_text().splitlines()]
        real_interpret = any(r['kind'] == 'interpret' and r['source'] == 'model' for r in records)
        marker = 'PERSON2_VOICE_INTERPRET_PASS' if args.interpret_only else 'PERSON2_VOICE_MODEL_PASS'
        return int(bool(host_code or game_code or marker not in content or not real_interpret
                        or 'SCRIPT ERROR' in content or 'ERROR:' in content))
    finally:
        for process in (host, game):
            if process is not None and process.poll() is None:
                process.terminate()
                process.wait(timeout=10)


if __name__ == '__main__':
    raise SystemExit(main())
