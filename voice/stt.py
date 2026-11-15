"""
voice/stt.py — Person 3 local speech-to-text module
======================================================
Turns microphone audio into a transcript string + latency.
Uses faster-whisper (CTranslate2 backend). 100% local/offline, no paid API.

Model license: Whisper weights are MIT-licensed (OpenAI).
faster-whisper is MIT-licensed. sounddevice/soundfile are BSD/LGPL.

Usage (from Python):
    from voice.stt import transcribe
    text, latency_s = transcribe()      # push-to-talk: records until key released
    text, latency_s = transcribe(audio_path="clip.wav")  # from a file

Returns:
    (str, float) — (transcript, end-to-end latency in seconds)
                   The transcript is the raw text; do NOT interpret here.
                   Interpretation is the Kiro interpreter's job.
"""

from __future__ import annotations

import os
import time
import tempfile
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Configuration — change MODEL_SIZE to swap to a larger model.
# "base.en" (~145 MB) is the default for low latency on a mid-range GPU/CPU.
# Options (English-only models): tiny.en, base.en, small.en, medium.en
# Options (multilingual):        tiny, base, small, medium, large-v3
# ---------------------------------------------------------------------------
MODEL_SIZE: str = os.environ.get("WHISPER_MODEL", "base.en")
DEVICE: str = os.environ.get("WHISPER_DEVICE", "auto")   # "auto" | "cuda" | "cpu"
COMPUTE_TYPE: str = os.environ.get("WHISPER_COMPUTE", "default")
# default sample rate expected by Whisper
SAMPLE_RATE: int = 16_000


def _load_model():
    """Lazy-load faster-whisper model (cached as module-level singleton)."""
    global _MODEL
    if _MODEL is not None:
        return _MODEL
    try:
        from faster_whisper import WhisperModel  # type: ignore
    except ImportError as exc:
        raise ImportError(
            "faster-whisper is not installed. Run:\n"
            "  pip install faster-whisper\n"
            "then download the model the first time by calling transcribe()."
        ) from exc

    device = DEVICE
    if device == "auto":
        try:
            import torch  # type: ignore
            device = "cuda" if torch.cuda.is_available() else "cpu"
        except ImportError:
            device = "cpu"

    compute = COMPUTE_TYPE
    if compute == "default":
        compute = "float16" if device == "cuda" else "int8"

    print(f"[voice/stt] Loading faster-whisper model '{MODEL_SIZE}' on {device} ({compute})…")
    _MODEL = WhisperModel(MODEL_SIZE, device=device, compute_type=compute)
    print("[voice/stt] Model ready.")
    return _MODEL


_MODEL = None  # module-level singleton


def transcribe(
    audio_path: Optional[str] = None,
    *,
    duration_s: float = 5.0,
    language: str = "en",
) -> tuple[str, float]:
    """
    Transcribe audio and return (transcript_text, latency_seconds).

    Parameters
    ----------
    audio_path : str or None
        If given, transcribe this WAV/MP3/etc. file.
        If None, record from the default microphone for `duration_s` seconds.
    duration_s : float
        Recording duration when audio_path is None (push-to-talk callers
        should use record_until_keyup() instead and pass the resulting path).
    language : str
        BCP-47 language code hint for Whisper (default "en").

    Returns
    -------
    (str, float)
        transcript : the raw transcribed text, stripped of leading/trailing whitespace.
        latency_s  : wall-clock seconds from the START of transcription (not recording).
    """
    model = _load_model()

    if audio_path is None:
        audio_path = _record_mic(duration_s)
        _temp_file = audio_path
    else:
        _temp_file = None

    t0 = time.perf_counter()
    segments, _info = model.transcribe(audio_path, language=language, beam_size=5)
    text = " ".join(seg.text for seg in segments).strip()
    latency_s = time.perf_counter() - t0

    if _temp_file:
        try:
            Path(_temp_file).unlink(missing_ok=True)
        except OSError:
            pass

    return text, latency_s


def record_until_keyup(key: str = "space") -> str:
    """
    Record microphone audio while `key` is held down (push-to-talk).
    Returns path to a temporary WAV file (caller is responsible for cleanup,
    or just pass it to transcribe() which cleans it up automatically).

    Requires the `keyboard` package: pip install keyboard
    Requires the `sounddevice` and `soundfile` packages: pip install sounddevice soundfile

    Parameters
    ----------
    key : str
        Keyboard key to hold. Default "space". Any key name accepted by the
        `keyboard` library works (e.g. "right ctrl", "mouse4").
    """
    try:
        import keyboard as kb  # type: ignore
        import sounddevice as sd  # type: ignore
        import soundfile as sf  # type: ignore
        import numpy as np  # type: ignore
    except ImportError as exc:
        raise ImportError(
            "Push-to-talk requires extra packages:\n"
            "  pip install keyboard sounddevice soundfile numpy"
        ) from exc

    print(f"[voice/stt] Hold '{key}' to speak, release to stop recording…")

    # Wait for key press
    kb.wait(key, suppress=False)

    frames: list = []
    stream = sd.InputStream(samplerate=SAMPLE_RATE, channels=1, dtype="float32")
    stream.start()

    print("[voice/stt] Recording…")
    while kb.is_pressed(key):
        chunk, _ = stream.read(SAMPLE_RATE // 10)   # 100 ms chunks
        frames.append(chunk)

    stream.stop()
    stream.close()
    print("[voice/stt] Done recording.")

    audio = np.concatenate(frames, axis=0) if frames else np.zeros((SAMPLE_RATE,), dtype="float32")
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    sf.write(tmp.name, audio, SAMPLE_RATE)
    return tmp.name


def _record_mic(duration_s: float) -> str:
    """Record `duration_s` seconds from the default mic. Returns temp WAV path."""
    try:
        import sounddevice as sd  # type: ignore
        import soundfile as sf  # type: ignore
        import numpy as np  # type: ignore
    except ImportError as exc:
        raise ImportError(
            "Microphone recording requires:\n"
            "  pip install sounddevice soundfile numpy"
        ) from exc

    print(f"[voice/stt] Recording {duration_s}s from mic…")
    audio = sd.rec(
        int(duration_s * SAMPLE_RATE),
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype="float32",
    )
    sd.wait()
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    import numpy as np  # noqa: F811
    sf.write(tmp.name, audio, SAMPLE_RATE)
    return tmp.name
