"""
voice/push_to_talk.py — CLI done-test helper (Person 3)
=========================================================
Run this script on the GPU PC to execute the Track D done-test.

Usage:
    python -m voice.push_to_talk              # hold SPACE to record (default)
    python -m voice.push_to_talk --key ctrl   # hold Right Ctrl to record
    python -m voice.push_to_talk --file clip.wav  # transcribe from a file

Each run prints: transcript | latency | timestamp.
Results must be recorded manually in voice/README.md — this script does
NOT auto-claim any accuracy numbers.
"""

from __future__ import annotations

import argparse
import datetime
import sys
from pathlib import Path

# Allow running as `python -m voice.push_to_talk` from repo root
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from voice.stt import transcribe, record_until_keyup  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Person 3 — Track D done-test: local push-to-talk transcription"
    )
    parser.add_argument(
        "--key", default="space",
        help="Key to hold for push-to-talk recording (default: space). "
             "Ignored if --file is given.",
    )
    parser.add_argument(
        "--file", default=None,
        help="Transcribe an existing audio file instead of recording from mic.",
    )
    parser.add_argument(
        "--loops", type=int, default=1,
        help="How many push-to-talk rounds to run (default: 1). "
             "Run 10 for the done-test.",
    )
    args = parser.parse_args()

    print("=" * 60)
    print("Track D done-test: local speech-to-text (voice/stt.py)")
    print("Model: faster-whisper  |  offline, no network calls")
    print("=" * 60)

    for i in range(args.loops):
        if args.loops > 1:
            print(f"\n--- Round {i + 1}/{args.loops} ---")

        if args.file:
            text, latency_s = transcribe(audio_path=args.file)
        else:
            wav_path = record_until_keyup(key=args.key)
            text, latency_s = transcribe(audio_path=wav_path)

        ts = datetime.datetime.now().isoformat(timespec="seconds")
        print(f"\nTranscript : {text!r}")
        print(f"Latency    : {latency_s:.3f}s  (transcription only; recording time not included)")
        print(f"Timestamp  : {ts}")
        print()
        print("NOTE: Record this result manually in voice/README.md.")

    print("Done. No network calls were made during transcription.")


if __name__ == "__main__":
    main()
