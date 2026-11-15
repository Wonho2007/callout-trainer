"""PC-side live STT/interpreter check using unchanged Person 3 source.

Standalone microphone acceptance tool; proposals are NOT dispatched into Godot.
Raw microphone audio is held in memory and not saved. Telemetry is gitignored.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import time

# Keep DLL directory handles alive on Windows. No global PATH changes.
_DLL_HANDLES = []


def configure_cuda():
    if os.name != 'nt':
        return
    packages = Path(sys.prefix) / 'Lib' / 'site-packages' / 'nvidia'
    directories = sorted({p.parent for p in packages.rglob('*.dll')})
    for directory in directories:
        _DLL_HANDLES.append(os.add_dll_directory(str(directory)))
    os.environ['PATH'] = os.pathsep.join(map(str, directories)) + os.pathsep + os.environ.get('PATH', '')


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--model-path', type=Path, required=True)
    parser.add_argument('--llm-model', default='llama3.1:8b')
    parser.add_argument('--host', default='http://127.0.0.1:11434')
    parser.add_argument('--key', default='right ctrl')
    parser.add_argument('--loops', type=int, default=5)
    parser.add_argument('--file', type=Path)
    parser.add_argument('--preflight', action='store_true')
    parser.add_argument('--output', type=Path, default=Path('runs/live-voice.jsonl'))
    args = parser.parse_args()
    configure_cuda()
    os.environ['WHISPER_MODEL'] = str(args.model_path.resolve())
    os.environ['WHISPER_DEVICE'] = 'cuda'
    os.environ['WHISPER_COMPUTE'] = 'float16'
    os.environ['HF_HUB_OFFLINE'] = '1'
    sys.path.insert(0, str(args.source_root.resolve()))
    import numpy as np
    import sounddevice as sd
    from voice import stt
    from comms import interpreter as I, vocabulary as V
    from recording.decision_log import make_record

    print('Standalone live voice check; proposals are not sent to the game.', flush=True)
    print('Microphone audio stays in memory; transcript/prompt/output telemetry is saved locally.', flush=True)
    print('Default input:', sd.query_devices(kind='input')['name'], flush=True)
    print('CUDA model:', args.model_path, flush=True)
    started = time.perf_counter()
    stt._load_model()
    # Execute a real CUDA encode/decode, including lazy library loading, before mic capture.
    silence, seconds = stt.transcribe(audio=np.zeros(16000, dtype=np.float32))
    print(json.dumps({'preflight_s': time.perf_counter() - started,
                      'silence_transcript': silence, 'silence_transcribe_s': seconds}), flush=True)
    if args.preflight:
        return
    vocab = V.build_vocabulary(scenario_agents=['Yoru', 'Omen'])
    client = I.OllamaClient(args.llm_model, host=args.host, timeout_s=10)
    # Warm the LLM before the user begins speaking, without dispatching any action.
    I.interpret('two on heaven', vocab, client)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    origin = time.perf_counter()
    loops = 1 if args.file else args.loops
    for index in range(loops):
        print(f'\nRound {index + 1}/{loops}: hold {args.key.upper()}, speak, then release. Ctrl+C exits.', flush=True)
        # Utterance wall time is not fabricated from STT latency. The existing recorder
        # does not return exact key-down time, so record only capture-return/completion times.
        if args.file:
            audio = str(args.file)
        else:
            audio = stt.record_until_keyup(key=args.key)
        capture_finished_s = time.perf_counter() - origin
        post_capture = time.perf_counter()
        text, stt_seconds = stt.transcribe(audio=audio)
        log = []
        interpreted = I.interpret(text, vocab, client, on_log=log.append)
        finished_s = time.perf_counter() - origin
        row = dict(index=index + 1, transcript=text, stt_s=stt_seconds,
                   capture_finished_s=capture_finished_s, completed_s=finished_s,
                   post_capture_s=time.perf_counter() - post_capture,
                   result=interpreted, audio_source='file' if args.file else 'default_microphone',
                   source_root=str(args.source_root), whisper_model=str(args.model_path))
        # Diagnostic sequence only, not game ticks or a game fairness proof.
        row['interpret_record'] = make_record(tick=index, kind='interpret',
            inputs={'transcript': text, 'vocabulary': vocab}, system=log[0]['system'],
            prompt=log[0]['prompt'], raw_output=log[0]['raw'], parsed=log[0]['parsed'],
            source=log[0]['source'])
        with args.output.open('a', encoding='utf-8') as output:
            output.write(json.dumps(row) + '\n')
        print(f'Transcript: {text!r}', flush=True)
        print(f'STT: {stt_seconds:.3f}s | after release: {row["post_capture_s"]:.3f}s | {interpreted["source"]}', flush=True)
        print('Interpretation:', json.dumps({k: interpreted[k] for k in
              ('result', 'proposal', 'question', 'reason') if k in interpreted}), flush=True)
    print('Done. Verify what was actually spoken before claiming accuracy.', flush=True)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nMicrophone session stopped.', flush=True)
