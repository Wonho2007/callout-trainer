"""
recording/decision_log.py — non-determinism decision log (Person 3, Step 5.4 / 6)
==================================================================================
Because the LLM is non-deterministic, we cannot replay to the same output to prove
fairness or to grade. So we LOG every interpret/decide call: the exact copied inputs
the model was given, the full prompt, the raw model output, the parsed result, the
source (model / deterministic_fallback / deterministic), and the tick. This recorded
trace is what the fairness audit (recording/evidence_audit.*) and the later grader read.

Fairness contract enforced here (AGENTS.md "Fairness boundary"):
  - The logged `inputs` are the ONLY things the model was allowed to see: copied delayed
    observations, the bot's own state, its local beliefs, the public-signal allowlist,
    and the grounding vocabulary. This logger shallow-validates that no forbidden key
    (truth, scene, enemy transforms, spectator/minimap) appears, and records everything
    so the audit can prove the logged inputs are a subset of what the bot could observe
    by that tick. Truth is kept in a SEPARATE stream the model never sees.

Records are JSON lines (one object per decision) written under user://runs/ at runtime
(here: a caller-provided path). Default to runs/ which is gitignored — never commit logs.
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any, Optional

RECORD_VERSION = "decision_log.v1"

# Keys that must NEVER appear in a decision's `inputs` (they would be a truth leak).
FORBIDDEN_INPUT_KEYS = {
    "truth", "ground_truth", "scene", "scene_tree", "enemy_transform",
    "enemy_transforms", "enemy_positions", "spectator", "minimap", "global_truth",
    "world", "node", "nodes",
}


class LeakError(ValueError):
    """Raised when a decision record's inputs contain a forbidden (truth-leaking) key."""


def _assert_no_leak(inputs: dict, _path: str = "inputs") -> None:
    """Recursively reject forbidden keys anywhere in the inputs structure."""
    if isinstance(inputs, dict):
        for k, v in inputs.items():
            if isinstance(k, str) and k.lower() in FORBIDDEN_INPUT_KEYS:
                raise LeakError(
                    f"Forbidden key {k!r} at {_path}.{k}: the policy may not see truth/scene/"
                    f"spectator data. Pass only copied delayed observations, own state, "
                    f"local beliefs, allowed public signals and vocabulary."
                )
            _assert_no_leak(v, f"{_path}.{k}")
    elif isinstance(inputs, list):
        for i, v in enumerate(inputs):
            _assert_no_leak(v, f"{_path}[{i}]")


def make_record(
    *,
    tick: int,
    kind: str,
    inputs: dict,
    system: Optional[str],
    prompt: Optional[str],
    raw_output: Optional[str],
    parsed: Any,
    source: str,
    extra: Optional[dict] = None,
) -> dict:
    """Build one decision record. Raises LeakError if inputs contain forbidden keys.

    Parameters
    ----------
    tick : int        simulation tick at which the decision was made.
    kind : str        "interpret" (transcript->comm) or "decide" (comm->goal/intent).
    inputs : dict     the COPIED values the model was allowed to see (observations,
                      own state, local beliefs, public signals, vocabulary). No truth.
    system / prompt   the exact strings sent to the model (None for deterministic).
    raw_output : str  the raw model text (None for pure-deterministic calls).
    parsed            the validated/parsed structured result.
    source : str      "model" | "deterministic_fallback" | "deterministic".
    extra : dict      optional additional copied context (e.g. speaker_id, recipient_id).
    """
    if not isinstance(tick, int) or isinstance(tick, bool) or tick < 0:
        raise ValueError(f"tick must be a non-negative int, got {tick!r}")
    _assert_no_leak(inputs)
    record = {
        "record_version": RECORD_VERSION,
        "wall_time": time.time(),
        "tick": tick,
        "kind": kind,
        "source": source,
        "inputs": inputs,
        "prompt": {"system": system, "user": prompt},
        "raw_output": raw_output,
        "parsed": parsed,
    }
    if extra:
        record["extra"] = extra
    return record


class DecisionLog:
    """Append-only JSON-lines decision log. Writes to runs/ (gitignored) by default."""

    def __init__(self, path: str | Path = "runs/decision_log.jsonl") -> None:
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def append(self, record: dict) -> None:
        with self.path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")

    def log_interpret(
        self, *, tick: int, inputs: dict, result: dict,
        system: Optional[str] = None, prompt: Optional[str] = None,
        raw_output: Optional[str] = None, extra: Optional[dict] = None,
    ) -> dict:
        """Convenience for logging an interpreter call. `result` is interpret()'s return."""
        record = make_record(
            tick=tick, kind="interpret", inputs=inputs,
            system=system or result.get("_system"),
            prompt=prompt or result.get("_prompt"),
            raw_output=raw_output if raw_output is not None else result.get("raw"),
            parsed={k: v for k, v in result.items() if k != "raw"},
            source=result.get("source", "unknown"),
            extra=extra,
        )
        self.append(record)
        return record

    def read_all(self) -> list[dict]:
        if not self.path.exists():
            return []
        return [json.loads(line) for line in self.path.read_text(encoding="utf-8").splitlines() if line.strip()]
