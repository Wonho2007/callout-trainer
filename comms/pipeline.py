"""
comms/pipeline.py — transcript -> interpret -> belief -> intent glue (Person 3, final sprint §1)
=================================================================================================
One pure, headless, offline-testable path that wires the existing pieces end to end and is
shaped so a LIVE MIC transcript drops in unchanged on Person 2's PC:

    transcript (+timestamp)
      -> comms.interpreter.interpret()        (model client, or deterministic fallback)
      -> comms.v1 message                     (trusted adapter stamps ids/ticks/expiry)
      -> told observation (reaction delay)    (what a bot is ALLOWED to hear, delayed)
      -> belief update                        (mirrors belief/region_belief.gd exactly)
      -> snapshot {bot_id, tick, enemies, evidence_ids}   (what Person 2's intent gate reads)

Every interpret/decide call is logged to a recording.decision_log.DecisionLog with copied
inputs, the exact prompt, the raw model output, the parsed result, the source, and the tick,
so fairness is proven against the recorded log (recording/evidence_audit, comms/fairness_audit).

Why a Python belief mirror? belief/region_belief.gd is the authoritative in-engine module.
It cannot run without Godot. `ReportBelief` here reproduces its report-update math EXACTLY
(same priors, same hedge strengths {sure:0.9, think:0.7, unsure:0.4}, same likelihood and
Bayesian normalization) so the headless glue test exercises the real numbers. If the two ever
disagree, the .gd file wins; keep them in lockstep (tests/person3/test_pipeline.py guards this).

TRANSCRIPT HAND-OFF SHAPE (confirm with Person 2 so the live mic plugs in with no rework):
    A transcript is {"text": str, "timestamp_s": float}. voice.stt.transcribe() returns
    (text, latency_s); `Transcript.from_stt(text, latency_s, started_s=...)` adapts it. The
    pipeline turns timestamp_s into issued_tick via `tick_rate_hz`. Nothing else about the
    source matters: typed string in tests, mic on the PC, same call.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

from comms import interpreter as I
from comms import vocabulary as V
from recording.decision_log import DecisionLog, make_record

# Hedge -> belief strength. MUST match belief/region_belief.gd _report().
HEDGE_STRENGTH = {"sure": 0.9, "think": 0.7, "unsure": 0.4}


# ---------------------------------------------------------------------------
# Transcript hand-off (the shape the live mic / STT plugs into)
# ---------------------------------------------------------------------------

@dataclass
class Transcript:
    """What the interpreter consumes, regardless of source (typed or live mic)."""
    text: str
    timestamp_s: float = 0.0

    @classmethod
    def from_stt(cls, text: str, latency_s: float, started_s: float = 0.0) -> "Transcript":
        """Adapt voice.stt.transcribe()'s (text, latency_s) return + a start wall-time.

        timestamp_s is when the comm was SPOKEN (start), not when STT finished, so the
        reaction-delay clock is anchored to the utterance, not to transcription cost.
        """
        return cls(text=text, timestamp_s=started_s)


# ---------------------------------------------------------------------------
# Trusted adapter config (assigns the fields the model is NOT allowed to invent)
# ---------------------------------------------------------------------------

@dataclass
class PipelineConfig:
    bot_id: str                       # recipient teammate bot (e.g. "f0rsaken_omen")
    speaker_id: str = "player"        # the human player
    region_ids: list[str] = field(default_factory=lambda: list(V.REGION_IDS))
    enemy_ids: list[str] = field(default_factory=lambda: ["enemy_1"])
    scenario_agents: list[str] = field(default_factory=list)
    tick_rate_hz: float = 20.0        # sim ticks per second; timestamp_s * this -> issued_tick
    reaction_delay_ticks: int = 8     # delay before a told comm is available to the bot
    message_ttl_ticks: int = 200      # expires_tick = issued_tick + ttl


# ---------------------------------------------------------------------------
# Belief mirror of belief/region_belief.gd (report path), headless
# ---------------------------------------------------------------------------

class ReportBelief:
    """Headless mirror of belief/region_belief.gd for told enemy reports.

    Keeps a per-enemy probability distribution over region_ids and applies the SAME
    Bayesian update as the .gd module. Only the told/report and seen/clear content types
    the glue produces are implemented; the .gd file stays authoritative in-engine.
    """

    def __init__(self, bot_id: str, region_ids: list[str], enemy_ids: list[str]) -> None:
        assert bot_id and region_ids and enemy_ids
        assert len(set(region_ids)) == len(region_ids)
        assert len(set(enemy_ids)) == len(enemy_ids)
        self.bot_id = bot_id
        self.regions = list(region_ids)
        self.enemies = list(enemy_ids)
        uniform = 1.0 / len(self.regions)
        self.prob = {e: {r: uniform for r in self.regions} for e in self.enemies}
        self.tick = -1
        self._observations: dict[str, dict] = {}
        self._messages: dict[str, dict] = {}
        self.evidence: list[str] = []

    def apply(self, observation: dict, tick: int) -> dict:
        """Mirror region_belief.gd apply(): reject future/foreign, dedupe, update."""
        if tick < self.tick or not self._valid_observation(observation, tick):
            return {"ok": False, "reason": "invalid_or_unavailable_observation"}
        if observation["id"] in self._observations:
            same = self._observations[observation["id"]] == observation
            return {"ok": same, "reason": "duplicate_observation"}
        content = observation["content"]
        reason = "unsupported_content"
        if observation["source"] == "told" and content.get("type") == "comms":
            reason = self._report(observation, tick)
        if reason not in ("ok", "duplicate_message"):
            return {"ok": False, "reason": reason}
        self.tick = tick
        self._observations[observation["id"]] = dict(observation)
        self.evidence.append(observation["id"])
        return {"ok": True, "reason": reason}

    def _valid_observation(self, o: dict, tick: int) -> bool:
        keys = {"id", "bot_id", "event_tick", "available_tick", "source", "speaker_id", "content"}
        if not isinstance(o, dict) or set(o.keys()) != keys:
            return False
        return (
            isinstance(o["id"], str) and o["id"]
            and o["bot_id"] == self.bot_id
            and isinstance(o["event_tick"], int) and isinstance(o["available_tick"], int)
            and o["event_tick"] <= o["available_tick"] <= tick
            and isinstance(o["speaker_id"], str) and o["speaker_id"]
            and isinstance(o["content"], dict)
        )

    def _report(self, o: dict, tick: int) -> str:
        content = o["content"]
        if set(content.keys()) != {"type", "message"} or not isinstance(content["message"], dict):
            return "invalid_message"
        m = content["message"]
        if (m.get("recipient_id") != self.bot_id or m.get("speaker_id") != o["speaker_id"]
                or m.get("issued_tick", 0) > o["event_tick"]):
            return "invalid_message"
        mid = m.get("message_id")
        if mid in self._messages:
            return "duplicate_message" if self._messages[mid] == m else "conflicting_message_id"
        if tick >= m.get("expires_tick", 0):
            return "expired"
        region = m["payload"]["region_id"]
        if region not in self.regions:
            return "unknown_region"
        strength = HEDGE_STRENGTH[m["payload"]["hedge"]]
        n = len(self.regions)
        for enemy in self.enemies:
            likelihood = {
                c: (strength if c == region else 0.0) + (1.0 - strength) / n
                for c in self.regions
            }
            self._update(enemy, likelihood)
        self._messages[mid] = dict(m)
        return "ok"

    def _update(self, enemy: str, likelihood: dict) -> None:
        total = 0.0
        for r in self.regions:
            self.prob[enemy][r] *= likelihood[r]
            total += self.prob[enemy][r]
        for r in self.regions:
            self.prob[enemy][r] /= total

    def snapshot(self) -> dict:
        return {
            "bot_id": self.bot_id,
            "tick": self.tick,
            "enemies": {e: dict(self.prob[e]) for e in self.enemies},
            "evidence_ids": list(self.evidence),
        }


# ---------------------------------------------------------------------------
# The pipeline
# ---------------------------------------------------------------------------

class CommsPipeline:
    """End-to-end glue: transcript -> interpret -> (report) belief update -> snapshot.

    Non-report proposals (clarify/unsupported/command/empty) are interpreted and LOGGED
    but do not touch the belief (a command is an intent for Person 2's executor, not an
    enemy sighting; clarify/unsupported produce no belief change by design).
    """

    def __init__(self, config: PipelineConfig, client: Optional[I.ModelClient] = None,
                 log: Optional[DecisionLog] = None) -> None:
        self.cfg = config
        self.client = client
        self.log = log
        self.vocab = V.build_vocabulary(
            scenario_agents=config.scenario_agents or None,
            region_ids=config.region_ids,
        )
        self.belief = ReportBelief(config.bot_id, config.region_ids, config.enemy_ids)
        self._seq = 0

    # -- public inputs (either call works; from_stt feeds the live mic path) --

    def handle_text(self, text: str, timestamp_s: float = 0.0) -> dict:
        return self.handle(Transcript(text=text, timestamp_s=timestamp_s))

    def handle(self, transcript: Transcript) -> dict:
        """Run one comm through the whole path. Returns a result dict:
            {result, source, proposal?, question?/reason?, message?, observation?,
             snapshot?, applied: bool, apply_reason?}
        and appends exactly one decision-log record (via the interpret on_log hook).
        """
        issued_tick = int(round(transcript.timestamp_s * self.cfg.tick_rate_hz))
        self._seq += 1

        # Copied inputs the interpreter is allowed to see — logged for the fairness audit.
        # NOTHING here is truth/scene/spectator; it is vocabulary + the bot's own belief.
        inputs = {
            "transcript": transcript.text,
            "timestamp_s": transcript.timestamp_s,
            "vocabulary": {
                "region_ids": list(self.vocab["region_ids"]),
                "agents": {k: list(v) for k, v in self.vocab.get("agents", {}).items()},
            },
            "local_belief_snapshot": self.belief.snapshot(),
            "own_state": {"bot_id": self.cfg.bot_id},
        }

        captured: dict = {}

        def _on_log(rec: dict) -> None:
            captured.update(rec)
            if self.log is not None:
                record = make_record(
                    tick=issued_tick, kind="interpret", inputs=inputs,
                    system=rec.get("system"), prompt=rec.get("prompt"),
                    raw_output=rec.get("raw"), parsed=rec.get("parsed"),
                    source=rec.get("source", "unknown"),
                    extra={"speaker_id": self.cfg.speaker_id, "recipient_id": self.cfg.bot_id,
                           "message_seq": self._seq},
                )
                # make_record copies inputs by reference; the audit reads evidence_ids off
                # the observation, so attach them so a report decision is auditable.
                self.log.append(record)

        interp = I.interpret(transcript.text, self.vocab, self.client, on_log=_on_log)

        out = {"result": interp["result"], "source": interp["source"],
               "transcript": transcript.text, "applied": False}
        for k in ("proposal", "question", "reason"):
            if k in interp:
                out[k] = interp[k]

        if interp["result"] != "report":
            return out  # command/clarify/unsupported/empty: logged, no belief change

        # -- report -> comms.v1 -> told observation (reaction delay) -> belief --
        payload = interp["proposal"]["payload"]
        message = self._make_report_message(payload, issued_tick)
        available_tick = issued_tick + self.cfg.reaction_delay_ticks
        observation = self._told_observation(message, available_tick)
        apply_res = self.belief.apply(observation, available_tick)

        out.update({
            "message": message,
            "observation": observation,
            "applied": apply_res["ok"],
            "apply_reason": apply_res["reason"],
            "snapshot": self.belief.snapshot(),
        })
        return out

    # -- trusted adapter: the fields the model may NOT invent (COMMANDS.md) --

    def _make_report_message(self, payload: dict, issued_tick: int) -> dict:
        return {
            "schema_version": "comms.v1",
            "message_id": f"{self.cfg.speaker_id}-{self._seq:04d}",
            "speaker_id": self.cfg.speaker_id,
            "recipient_id": self.cfg.bot_id,
            "issued_tick": issued_tick,
            "expires_tick": issued_tick + self.cfg.message_ttl_ticks,
            "kind": "report",
            "payload": {
                "action": "report_enemy",
                "region_id": payload["region_id"],
                "count": payload["count"],
                "hedge": payload["hedge"],
            },
        }

    def _told_observation(self, message: dict, available_tick: int) -> dict:
        return {
            "id": f"obs-{message['message_id']}",
            "bot_id": message["recipient_id"],
            "event_tick": message["issued_tick"],
            "available_tick": available_tick,
            "source": "told",
            "speaker_id": message["speaker_id"],
            "content": {"type": "comms", "message": dict(message)},
        }
