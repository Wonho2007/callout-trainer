"""
tools/demo_trace.py — bot -> scenario -> behavior-trace demo runner (Person 3, final sprint §5)
================================================================================================
Runs a scripted sequence of typed comms through the full Person 3 path and prints a readable
trace, then writes + audits the decision log. On Person 2's PC, swap the typed comms for live
mic transcripts (voice.stt.transcribe()) and pass a real OllamaClient with --model; the trace
and audit are identical. This is the headless rehearsal of the live demo chain:

    player speaks -> STT text -> grounded LLM interprets -> belief updates -> teammate reacts

HONEST LABELING (say this in the demo, do not overclaim):
  - "grounded, not trained": the model is given the vocabulary + schema at runtime; no
    fine-tuning, no VALORANT dataset. Free/local only.
  - "pro-inspired adaptation": enemy/branch lines are inspired by the annotated VOD round, not
    a claim the bots reproduce the pros. Branches are authored, weighted, synthetic.
  - the deterministic fallback is a REQUIRED circuit breaker; when it fires, the trace shows
    source=deterministic_fallback and a visible reason. That is a feature, not a failure.
  - no transfer / win-rate / "measured savings" claims. Report only what the trace shows.

Usage:
    python tools/demo_trace.py                       # headless, deterministic (no model)
    python tools/demo_trace.py --model llama3.1:8b   # with local Ollama on the PC
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
if str(REPO) not in sys.path:
    sys.path.insert(0, str(REPO))

from comms import interpreter as I
from comms import vocabulary as V
from comms.pipeline import CommsPipeline, PipelineConfig
from recording.decision_log import DecisionLog
from recording.fairness_audit import audit_log


def _alias_for(region_id: str) -> str:
    for word, rid in V.REGION_ALIASES.items():
        if rid == region_id:
            return word
    return region_id


def main() -> None:
    ap = argparse.ArgumentParser(description="Run the Person 3 comms->belief trace demo.")
    ap.add_argument("--model", default=None, help="Ollama model name (omit for deterministic).")
    ap.add_argument("--host", default="http://localhost:11434")
    ap.add_argument("--log", default="runs/demo_trace.jsonl")
    args = ap.parse_args()

    client = I.OllamaClient(model=args.model, host=args.host) if args.model else None

    r0, r1 = V.REGION_IDS[0], V.REGION_IDS[1]
    # A short scripted round: two reports concentrate belief, a clarify, an unsupported.
    script = [
        f"two {_alias_for(r0)}",
        f"i think one more {_alias_for(r0)}",
        "flash that smoke",
        f"maybe one {_alias_for(r1)}",
        "go defuse the spike",
    ]

    cfg = PipelineConfig(bot_id="omen_bot", speaker_id="player",
                         region_ids=list(V.REGION_IDS), enemy_ids=["e1", "e2"],
                         scenario_agents=["Omen"])
    log_path = Path(args.log)
    if log_path.exists():
        log_path.unlink()
    log = DecisionLog(log_path)
    pipe = CommsPipeline(cfg, client=client, log=log)

    mode = f"model={args.model}" if client else "deterministic (no model)"
    print(f"=== Person 3 comms trace demo [{mode}] ===")
    print(f"bot={cfg.bot_id}  regions={cfg.region_ids}\n")

    observations = []
    for i, text in enumerate(script):
        out = pipe.handle_text(text, timestamp_s=float(i + 1))
        line = f"[t={i+1:>2}s] player: {text!r:28} -> {out['result']:11} via {out['source']}"
        if out["result"] == "report":
            pl = out["message"]["payload"]
            line += f"  | report {pl['region_id']} count={pl['count']} hedge={pl['hedge']} applied={out['applied']}"
            observations.append(out["observation"])
        elif out["result"] == "command":
            pl = out["proposal"]["payload"]
            line += f"  | command {pl['action']} -> {pl['target_id']} ({pl['timing']['mode']})"
        elif out["result"] == "clarify":
            line += f"  | ask: {out['question']!r}"
        elif out["result"] == "unsupported":
            line += f"  | honest no: {out['reason']!r}"
        print(line)

    snap = pipe.belief.snapshot()
    print("\n--- teammate belief after the round (enemy e1) ---")
    for region, prob in sorted(snap["enemies"]["e1"].items(), key=lambda kv: -kv[1]):
        bar = "#" * int(round(prob * 40))
        print(f"  {region:10} {prob:5.3f} {bar}")

    records = log.read_all()
    report = audit_log(records, observations=observations)
    print(f"\n--- fairness audit over the recorded decision log ---")
    print(f"  records: {len(records)}   checked: {report.checked}   OK: {report.ok}")
    if not report.ok:
        for e in report.errors:
            print(f"  ERROR: {e}")
    print(f"  log written to: {log_path}")
    print("\nNote: 'grounded not trained'; branches are 'pro-inspired', not reproductions; "
          "no transfer/win-rate claims. The fallback firing is a feature (visible reason).")

    sys.exit(0 if report.ok else 1)


if __name__ == "__main__":
    main()
