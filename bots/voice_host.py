"""Local PC microphone/interpreter/goal host for the owned synthetic Godot scene.

All world access stays in Godot. This process receives copied available context and
static authored affordances only. Slow model work runs outside the game thread.
"""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
import queue
import socket
import sys
import threading
import time
import urllib.request

from live_voice import configure_cuda


GOAL_SYSTEM = '''Choose one teammate tactical goal. Return only a JSON object with exactly
goal, target_id, watch_region_id, evidence_ids. goal is hold, cover, reposition, or stop.
For stop both target_id and watch_region_id are null. Otherwise use a reachable target
and one of its authored watch regions from affordances. Never output coordinates.
Use only the supplied copied context. Reference only available observation IDs from
this context. Player reports are accepted information even if wrong; never compare
them against hidden truth or discount a player due to credibility/history. Preserve
explicit uncertainty. Prefer useful coverage of a fresh reported threat. Do not
invent evidence or enemy identity. Respect accepted commands; the game owns execution.
If no useful information exists, hold an authored safe reachable angle.'''


def warm_model(host, model):
    """Load before gameplay; this empty-prompt request makes no tactical decision."""
    request = urllib.request.Request(host + '/api/generate',
        data=json.dumps(dict(model=model, prompt='', stream=False, keep_alive='30m')).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=90) as response:
        json.load(response)


def goal_schema(context, affordances):
    reachable = context['own_state']['reachable_marker_ids']
    watches = sorted({region for marker in reachable for region in affordances.get(marker, [])})
    evidence = [o['id'] for o in context['observations'] if o['available_tick'] <= context['tick']]
    evidence_rule = {'type': 'array', 'items': {'type': 'string', **({'enum': evidence} if evidence else {})},
                     'maxItems': min(len(evidence), 8), 'uniqueItems': True}
    variants = []
    pairs = [(target, region) for target in reachable for region in affordances.get(target, [])]
    for target, region in [*pairs, (None, None)]:
        variants.append({'type': 'object', 'properties': {
            'goal': {'type': 'string', 'enum': ['stop'] if target is None else ['hold', 'cover', 'reposition']},
            'target_id': {'const': target}, 'watch_region_id': {'const': region},
            'evidence_ids': evidence_rule}, 'required': ['goal', 'target_id', 'watch_region_id', 'evidence_ids'],
            'additionalProperties': False})
    return {'anyOf': variants}


def validate_goal(value, context, affordances):
    if not isinstance(value, dict) or set(value) != {'goal', 'target_id', 'watch_region_id', 'evidence_ids'}:
        raise ValueError('invalid goal shape')
    if value['goal'] not in ('hold', 'cover', 'reposition', 'stop'):
        raise ValueError('unsupported goal')
    if value['goal'] == 'stop':
        if value['target_id'] is not None or value['watch_region_id'] is not None:
            raise ValueError('stop has target')
    else:
        target = value['target_id']
        if not isinstance(target, str) or target not in context['own_state']['reachable_marker_ids']:
            raise ValueError('unreachable target')
        if value['watch_region_id'] not in affordances.get(target, []):
            raise ValueError('unknown authored watch')
    ids = value['evidence_ids']
    allowed = {o['id'] for o in context['observations'] if o['available_tick'] <= context['tick']}
    if not isinstance(ids, list) or any(not isinstance(i, str) or i not in allowed for i in ids) or len(set(ids)) != len(ids):
        raise ValueError('evidence outside copied context')
    return value


def capture_for_game(host):
    """Bounded PTT capture that stops when the game disconnects, even while idle."""
    import keyboard
    import numpy as np
    import sounddevice as sd
    print('Hold V to speak...', flush=True)
    while not keyboard.is_pressed('v'):
        if host.closed.wait(0.02):
            return None
    session = host.hello['session']
    frames = []
    started = time.monotonic()
    with sd.InputStream(samplerate=16000, channels=1, dtype='float32') as stream:
        while keyboard.is_pressed('v') and not host.closed.is_set() and time.monotonic() - started < 15:
            chunk, overflowed = stream.read(800)
            if overflowed:
                print('Microphone overflow; please repeat this call.', flush=True)
                return None
            frames.append(chunk)
    if host.closed.is_set() or not frames:
        return None
    return session, np.concatenate(frames).flatten()


class EngineHost:
    def __init__(self, args, interpreter, vocabulary, make_record):
        self.args, self.I, self.V, self.make_record = args, interpreter, vocabulary, make_record
        self.sock = socket.create_connection(('127.0.0.1', args.port), timeout=10)
        self.sock.settimeout(0.2)
        self.sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        self.lock = threading.RLock()
        self.log_lock = threading.Lock()
        self.ready = threading.Event()
        self.closed = threading.Event()
        self.hello = None
        self.latest = None
        self.goals = queue.Queue(maxsize=1)
        self.seq = 0
        self.args.output.mkdir(parents=True, exist_ok=True)
        threading.Thread(target=self.receive, daemon=True).start()
        threading.Thread(target=self.decide, daemon=True).start()

    def log(self, name, row):
        with self.log_lock, (self.args.output / name).open('a', encoding='utf-8') as out:
            out.write(json.dumps(row, allow_nan=False) + '\n')

    def send(self, row):
        with self.lock:
            if not self.closed.is_set():
                try:
                    self.sock.sendall((json.dumps(row, allow_nan=False) + '\n').encode())
                except OSError:
                    self.closed.set()

    def receive(self):
        pending = b''
        last_ping = 0.0
        try:
            while not self.closed.is_set():
                now = time.monotonic()
                if self.hello and now - last_ping > 0.5:
                    self.send({'type': 'ping', 'session': self.hello['session']})
                    last_ping = now
                try:
                    chunk = self.sock.recv(65536)
                except socket.timeout:
                    continue
                if not chunk:
                    break
                pending += chunk
                if len(pending) > 1048576:
                    raise ValueError('oversize engine packet')
                while b'\n' in pending:
                    line, pending = pending.split(b'\n', 1)
                    packet = json.loads(line)
                    self.log('events.jsonl', packet)
                    kind = packet['type']
                    if kind == 'hello':
                        with self.lock:
                            self.hello = packet
                            self.latest = None
                        self.ready.set()
                        print('Game connected. Regions:', ', '.join(packet['regions']), flush=True)
                    elif self.hello and packet.get('session') == self.hello['session']:
                        if kind == 'context':
                            self.latest = packet
                            if not self.args.no_goals:
                                try:
                                    self.goals.get_nowait()
                                except queue.Empty:
                                    pass
                                self.goals.put_nowait((time.monotonic(), copy.deepcopy(packet), copy.deepcopy(self.hello)))
                        elif kind == 'comm_result':
                            result = packet['result']
                            print('Teammate:', result['status'], '/', result['reason_code'], flush=True)
                        elif kind == 'intent_result' and not packet['result']['ok']:
                            print('Goal fallback:', packet['result']['reason'], flush=True)
        except (OSError, ValueError, KeyError) as exc:
            if not self.closed.is_set():
                print('Game connection stopped:', exc, flush=True)
        finally:
            self.closed.set()
            self.ready.set()

    def decide(self):
        while not self.closed.is_set():
            try:
                received_at, packet, hello = self.goals.get(timeout=0.25)
            except queue.Empty:
                continue
            context = packet['context']
            if time.monotonic() - received_at > 0.75 or context['active_command'] or not context['own_state']['alive']:
                continue
            inputs = {'context': context, 'affordances': hello['affordances']}
            prompt = json.dumps(inputs, sort_keys=True, allow_nan=False)
            raw, parsed, source, error = None, None, 'deterministic_fallback', None
            started = time.perf_counter()
            try:
                # Reject forbidden context before it reaches the model.
                self.make_record(tick=context['tick'], kind='decide', inputs=inputs,
                    system=GOAL_SYSTEM, prompt=prompt, raw_output=None, parsed=None, source='model')
                request = urllib.request.Request(self.args.host + '/api/generate',
                    data=json.dumps(dict(model=self.args.goal_model, system=GOAL_SYSTEM, prompt=prompt,
                        stream=False, format=goal_schema(context, hello['affordances']),
                        options={'temperature': 0.3, 'num_predict': 128})).encode(),
                    headers={'Content-Type': 'application/json'})
                with urllib.request.urlopen(request, timeout=3) as response:
                    answer = json.load(response)
                raw = answer.get('response', '')
                parsed = validate_goal(json.loads(raw), context, hello['affordances'])
                source = 'model'
            except (OSError, ValueError, KeyError, TypeError) as exc:
                error = repr(exc)
            elapsed = time.perf_counter() - started
            record = self.make_record(tick=context['tick'], kind='decide', inputs=inputs,
                system=GOAL_SYSTEM, prompt=prompt, raw_output=raw, parsed=parsed, source=source,
                extra={'context_id': context['context_id'], 'elapsed_s': elapsed, 'error': error,
                       'session': packet['session'],
                       'model': self.args.goal_model, 'format': goal_schema(context, hello['affordances']),
                       'options': {'temperature': 0.3, 'num_predict': 128}})
            record['bot_id'] = context['bot_id']
            record['evidence_ids'] = list(parsed['evidence_ids']) if parsed else []
            self.log('models.jsonl', record)
            if self.closed.is_set() or not self.hello or self.hello['session'] != packet['session']:
                continue
            # Even a valid model response is discarded if the real game context aged out.
            if time.monotonic() - received_at >= (context['expires_tick'] - context['tick']) / 60.0:
                parsed = None
            if parsed is None:
                self.send({'type': 'model_failure', 'session': packet['session']})
                continue
            candidate = dict(parsed, context_id=context['context_id'], bot_id=context['bot_id'],
                             decision_id='model:' + context['context_id'])
            self.send({'type': 'intent', 'session': packet['session'], 'candidate': candidate})

    def transcript(self, text, captured_session, stt_s=0.0):
        hello = copy.deepcopy(self.hello)
        if not hello or hello['session'] != captured_session:
            print('Round changed during speech; please repeat the call.', flush=True)
            return
        self.seq += 1
        request_id = str(self.seq)
        direct = text.lower().strip(' .!?')
        # Final cue/cancel bypass expensive model generation. The executor still
        # validates readiness, identity, availability and expiry after ordinary delay.
        if direct in ('go', 'swing', 'go now', 'cancel', 'cancel that'):
            kind = 'cancel' if direct.startswith('cancel') else 'cue'
            tick = self.latest['context']['tick'] if self.latest else 0
            self.log('models.jsonl', self.make_record(tick=tick, kind='interpret',
                inputs={'transcript': text}, system=None, prompt=None, raw_output=None,
                parsed={'kind': kind}, source='deterministic',
                extra={'session': captured_session, 'stt_s': stt_s}))
            self.send(dict(type=kind, session=captured_session, id=request_id, transcript=text))
            return
        vocab = self.V.build_vocabulary(scenario_agents=['Yoru', 'Omen'], region_ids=hello['regions'])
        captured = []
        started = time.perf_counter()
        result = self.I.interpret(text, vocab, self.I.OllamaClient(self.args.model, host=self.args.host, timeout_s=3), on_log=captured.append)
        tick = self.latest['context']['tick'] if self.latest else 0
        for logged in captured:
            record = self.make_record(tick=tick, kind='interpret', inputs={'transcript': text, 'vocabulary': vocab},
                system=logged['system'], prompt=logged['prompt'], raw_output=logged['raw'],
                parsed=logged['parsed'], source=logged['source'],
                extra={'session': captured_session, 'stt_s': stt_s, 'interpret_s': time.perf_counter() - started})
            self.log('models.jsonl', record)
        packet = {k: v for k, v in result.items() if k in ('result', 'proposal', 'question', 'reason', 'source')}
        packet.update(type='proposal', session=captured_session, id=request_id, transcript=text)
        self.send(packet)
        print('Heard:', text, '|', result['result'], '|', result.get('question', result.get('proposal', result.get('reason'))), flush=True)


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--model-path', type=Path)
    parser.add_argument('--port', type=int, default=8765)
    parser.add_argument('--model', default='llama3.1:8b')
    parser.add_argument('--goal-model', default='qwen2.5:3b')
    parser.add_argument('--host', default='http://127.0.0.1:11434')
    parser.add_argument('--output', type=Path, default=Path('runs/voice-engine'))
    parser.add_argument('--text', help='Developer test injection; normal player input is microphone only')
    goals = parser.add_mutually_exclusive_group()
    goals.add_argument('--model-goals', dest='no_goals', action='store_false', help='Experimental; real-time goal acceptance is not established')
    goals.add_argument('--no-goals', dest='no_goals', action='store_true')
    parser.set_defaults(no_goals=True)
    parser.add_argument('--seconds', type=float, default=15, help='Developer test observation time')
    args = parser.parse_args()
    print('Warming local model before connecting to the round...', flush=True)
    warm_model(args.host, args.model)
    if not args.no_goals:
        warm_model(args.host, args.goal_model)
    sys.path.insert(0, str(args.source_root.resolve()))
    from comms import interpreter as I, vocabulary as V
    from recording.decision_log import make_record
    stt = None
    if args.text is None:
        if args.model_path is None:
            parser.error('microphone mode requires --model-path')
        configure_cuda()
        import os
        os.environ.update(WHISPER_MODEL=str(args.model_path.resolve()), WHISPER_DEVICE='cuda', WHISPER_COMPUTE='float16', HF_HUB_OFFLINE='1')
        from voice import stt
        stt._load_model()
    host = EngineHost(args, I, V, make_record)
    if not host.ready.wait(10) or host.closed.is_set():
        raise RuntimeError('No game handshake')
    host.send({'type': 'host_mode', 'session': host.hello['session'], 'model_goals': not args.no_goals})
    if args.text is not None:
        host.transcript(args.text, host.hello['session'])
        host.closed.wait(args.seconds)
    else:
        print('Hold V to speak. Calls: ' + ', '.join(host.hello['regions']) + '. Ctrl+C exits.', flush=True)
        while not host.closed.is_set():
            captured = capture_for_game(host)
            if captured is None:
                continue
            session, audio = captured
            text, seconds = stt.transcribe(audio=audio)
            host.transcript(text, session, seconds)
    host.closed.set()
    host.sock.close()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nVoice host stopped; game falls back safely.', flush=True)
