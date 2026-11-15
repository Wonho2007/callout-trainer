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
# "small.en" (~460 MB) gives high accuracy for tactical callouts.
# Options (English-only models): tiny.en, base.en, small.en, medium.en
# Options (multilingual):        tiny, base, small, medium, large-v3
# ---------------------------------------------------------------------------
MODEL_SIZE: str = os.environ.get("WHISPER_MODEL", "small.en")
DEVICE: str = os.environ.get("WHISPER_DEVICE", "auto")   # "auto" | "cuda" | "cpu"
COMPUTE_TYPE: str = os.environ.get("WHISPER_COMPUTE", "default")
# default sample rate expected by Whisper
SAMPLE_RATE: int = 16_000
CALLOUT_PROMPT: str = "VALORANT comms: heaven, hell, site, A main, B main, mid, garage, flash, smoke, rotate, planting, defusing, swing, short, long, CT, enemy."


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
    audio: Optional[str | np.ndarray] = None,
    audio_path: Optional[str] = None,
    *,
    duration_s: float = 5.0,
    language: str = "en",
) -> tuple[str, float]:
    """
    Transcribe audio and return (transcript_text, latency_seconds).

    Parameters
    ----------
    audio : str, np.ndarray, or None
        Audio data (numpy float32 array) or path to an audio file (WAV/FLAC/etc.).
        If None, records from the default microphone for `duration_s` seconds.
    audio_path : str or None
        Backwards-compatible alias for `audio`.
    duration_s : float
        Recording duration when audio is None (default 5.0s).
    language : str
        BCP-47 language code hint for Whisper (default "en").

    Returns
    -------
    (str, float)
        transcript : the raw transcribed text, stripped of leading/trailing whitespace.
        latency_s  : wall-clock seconds from the START of transcription (not recording).
    """
    import numpy as np

    model = _load_model()
    target_input = audio if audio is not None else audio_path

    if target_input is None:
        waveform = _record_mic(duration_s)
    elif isinstance(target_input, str):
        import soundfile as sf
        data, sr = sf.read(target_input, dtype="float32")
        if data.ndim > 1:
            data = data.mean(axis=1)
        if sr != SAMPLE_RATE:
            new_len = int(len(data) * SAMPLE_RATE / sr)
            data = np.interp(
                np.linspace(0.0, 1.0, new_len, endpoint=False),
                np.linspace(0.0, 1.0, len(data), endpoint=False),
                data,
            ).astype(np.float32)
        waveform = data
    elif isinstance(target_input, np.ndarray):
        waveform = target_input.astype(np.float32)
        if waveform.ndim > 1:
            waveform = waveform.mean(axis=1)
    else:
        raise ValueError(f"Unsupported audio input type: {type(target_input)}")

    # Auto-normalize volume if input is not silent (improves recognition on quiet/USB mics)
    max_val = float(np.max(np.abs(waveform))) if len(waveform) > 0 else 0.0
    if max_val > 1e-4:
        waveform = (waveform / max_val * 0.95).astype(np.float32)

    t0 = time.perf_counter()
    segments, _info = model.transcribe(
        waveform,
        language=language,
        beam_size=5,
        initial_prompt=CALLOUT_PROMPT,
    )
    text = " ".join(seg.text for seg in segments).strip()
    latency_s = time.perf_counter() - t0

    return text, latency_s


def record_until_keyup(key: str = "space") -> np.ndarray:
    """
    Record microphone audio while `key` is held down (push-to-talk).
    Returns a 1D float32 numpy array sampled at 16kHz.

    Requires the `keyboard` package: pip install keyboard
    Requires the `sounddevice` and `numpy` packages: pip install sounddevice numpy

    Parameters
    ----------
    key : str
        Keyboard key to hold. Default "space". Any key name accepted by the
        `keyboard` library works (e.g. "right ctrl", "mouse4").
    """
    try:
        import keyboard as kb  # type: ignore
        import sounddevice as sd  # type: ignore
        import numpy as np  # type: ignore
    except ImportError as exc:
        raise ImportError(
            "Push-to-talk requires extra packages:\n"
            "  pip install keyboard sounddevice numpy"
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

    if frames:
        return np.concatenate(frames, axis=0).flatten()
    return np.zeros((SAMPLE_RATE,), dtype=np.float32)


def _record_mic(duration_s: float) -> np.ndarray:
    """Record `duration_s` seconds from the default mic. Returns 1D float32 numpy array."""
    try:
        import sounddevice as sd  # type: ignore
        import numpy as np  # type: ignore
    except ImportError as exc:
        raise ImportError(
            "Microphone recording requires:\n"
            "  pip install sounddevice numpy"
        ) from exc

    print(f"[voice/stt] Recording {duration_s}s from mic…")
    audio = sd.rec(
        int(duration_s * SAMPLE_RATE),
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype="float32",
    )
    sd.wait()
    return audio.flatten()
