"""
docs/spike_measure.py — capability-spike measurement harness (Person 3, Step 3)
================================================================================
Times a fixed set of VALORANT comms through a local Ollama model via the project's own
interpreter, and reports per-comm latency + how many produced valid in-vocabulary output
vs. tripped the deterministic circuit breaker. Run ON THE GPU PC with Ollama serving.

Usage:
  python docs/spike_measure.py --model llama3.1:8b
  python docs/spike_measure.py --model qwen2.5:7b-instruct --host http://localhost:11434

This prints numbers; it does NOT write them anywhere. Paste the summary into the table in
docs/CAPABILITY_SPIKE.md. No result is claimed until a real run fills that table.
"""

from __future__ import annotations

import argparse
import statistics
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
if str(REPO) not in sys.path:
    sys.path.insert(0, str(REPO))

from comms import interpreter as I
from comms import vocabulary as V

# Fixed hand examples (the spike's "test set"). Deterministic, in-vocabulary targets.
COMMS = [
    "two on heaven",
    "i think someone's b main",
    "maybe one in pit",
    "flash heaven on my cue",
    "swing site with me",
    "they're pushing b main three of them",
    "one low in pit",
    "nothing on site",
]


def main() -> None:
    p = argparse.ArgumentParser(description="Measure local-LLM latency on the comms prompt.")
    p.add_argument("--model", default="llama3.1:8b")
    p.add_argument("--host", default="http://localhost:11434")
    p.add_argument("--timeout", type=float, default=30.0)
    args = p.parse_args()

    vocab = V.build_vocabulary(scenario_agents=["Omen", "Raze"])
    client = I.OllamaClient(model=args.model, host=args.host, timeout_s=args.timeout)

    print(f"model={args.model} host={args.host}")
    print("warming up (first call loads the model into VRAM)…")
    t0 = time.perf_counter()
    _ = I.interpret(COMMS[0], vocab, client)
    print(f"  cold first call: {time.perf_counter() - t0:.2f}s\n")

    latencies: list[float] = []
    model_ok = 0
    fell_back = 0
    for comm in COMMS:
        t = time.perf_counter()
        r = I.interpret(comm, vocab, client)
        dt = time.perf_counter() - t
        latencies.append(dt)
        src = r.get("source")
        if src == "model":
            model_ok += 1
        elif src == "deterministic_fallback":
            fell_back += 1
        summary = r["result"]
        if r["result"] in ("report", "command"):
            summary += f" {r['proposal']['payload']}"
        print(f"  {dt:5.2f}s  [{src:>22}]  {comm!r:40} -> {summary}")

    print("\n--- summary (paste into docs/CAPABILITY_SPIKE.md) ---")
    print(f"  comms run:            {len(COMMS)}")
    print(f"  valid model output:   {model_ok}/{len(COMMS)}")
    print(f"  tripped breaker:      {fell_back}/{len(COMMS)}")
    print(f"  warm latency median:  {statistics.median(latencies[1:]) if len(latencies) > 1 else latencies[0]:.2f}s")
    print(f"  warm latency min/max: {min(latencies[1:]) if len(latencies) > 1 else latencies[0]:.2f}s / {max(latencies):.2f}s")


if __name__ == "__main__":
    main()
