"""
comms/interpreter.py — grounded transcript -> structured comm (Person 3, Step 5.2)
===================================================================================
Turns a spoken/typed VALORANT comm into a validated comms.v1 PROPOSAL, grounded in the
scenario vocabulary. This is the LLM wrapper: the model proposes intent/target/timing
(or region/count/hedge); a trusted adapter (Person 2 side) later stamps message_id,
speaker_id, recipient_id, issued_tick, expires_tick. The interpreter never invents IDs,
ticks, coordinates, or regions outside the frozen vocabulary.

Hard rules honored here (docs/COMMANDS.md, AGENTS.md):
  - Only these actions exist: swing_together, throw_flash, report_enemy (+ cue/cancel,
    handled by the deterministic cue path, not the model). Unsupported asks -> honest
    "unsupported", never invented behavior.
  - Ambiguous target/region -> a clarify result ("Which entrance?"), never a guess.
  - A report count is a positive int or null; never infer "one" from "someone".
  - The deterministic parser is the REQUIRED circuit breaker: if the model is offline,
    times out, returns junk, or emits an illegal token, we fall back to it inside the
    same boundary. The fallback obeys the identical vocabulary restriction.

Output shape (a "proposal", not a full comms.v1 message):
  {"result": "report",  "proposal": {"kind":"report",  "payload":{...}}, "source": "..."}
  {"result": "command", "proposal": {"kind":"command", "payload":{...}}, "source": "..."}
  {"result": "clarify", "question": "Which entrance?",                   "source": "..."}
  {"result": "unsupported", "reason": "no action for 'plant'",           "source": "..."}
  {"result": "empty",   "reason": "nothing to interpret",                "source": "..."}
Every result also carries "transcript" and, for model attempts, "raw" (the raw model text)
so recording/decision_log can log exactly what happened.
"""

from __future__ import annotations

import json
import re
from typing import Callable, Optional, Protocol

from comms import vocabulary as V

# Actions that actually exist in comms.v1 (docs/COMMANDS.md). Anything else is unsupported.
COMMAND_ACTIONS = {"swing_together", "throw_flash"}
SWING_TIMINGS = {"now", "on_cue", "follow_player"}
FLASH_TIMINGS = {"now", "on_cue"}
HEDGES = {"sure", "think", "unsure"}

# Spoken hedge words -> canonical hedge. Absence of a hedge word defaults to "sure"
# ONLY for the deterministic path's explicit "I see" style; the model is told the rule.
HEDGE_WORDS = {
    "sure": "sure", "definitely": "sure", "confirmed": "sure", "for sure": "sure",
    "i see": "sure", "i saw": "sure",
    "think": "think", "i think": "think", "probably": "think", "pretty sure": "think",
    "unsure": "unsure", "maybe": "unsure", "might be": "unsure", "not sure": "unsure",
    "could be": "unsure", "i think maybe": "unsure",
}


# ---------------------------------------------------------------------------
# Model client protocol + implementations (local/free only; no paid API)
# ---------------------------------------------------------------------------

class ModelClient(Protocol):
    def generate(self, system: str, prompt: str) -> str:  # pragma: no cover - protocol
        """Return the model's raw text completion. Raise on failure/timeout."""
        ...


class OllamaClient:
    """Local Ollama HTTP client. Free, offline once the model is pulled.

    Does NOT import anything at module load; only when generate() is called, so the
    interpreter module imports fine on machines without the runtime (tests use a stub).
    """

    def __init__(self, model: str = "llama3.1:8b", host: str = "http://localhost:11434",
                 timeout_s: float = 20.0) -> None:
        self.model = model
        self.host = host.rstrip("/")
        self.timeout_s = timeout_s

    def generate(self, system: str, prompt: str) -> str:
        import urllib.request
        body = json.dumps({
            "model": self.model,
            "system": system,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.0},
            "format": "json",
        }).encode("utf-8")
        req = urllib.request.Request(
            f"{self.host}/api/generate", data=body,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=self.timeout_s) as resp:  # noqa: S310
            data = json.loads(resp.read().decode("utf-8"))
        return data.get("response", "")


# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You translate ONE VALORANT teammate's spoken comm into a single JSON object and nothing else.

Rules:
- Output ONLY compact JSON. No prose, no markdown, no explanation.
- Use ONLY the region ids, agents, abilities and weapons given in the vocabulary. Never invent a region, never output coordinates.
- Allowed results: "report", "command", "clarify", "unsupported", "empty".
- A "report" means an enemy sighting: {"result":"report","payload":{"action":"report_enemy","region_id":<id>,"count":<int|null>,"hedge":"sure|think|unsure"}}. Use null for count unless a number was clearly said; never infer 1 from "someone". Pick the hedge from the speaker's certainty words.
- A "command" is ONLY swing_together or throw_flash: {"result":"command","payload":{"action":"swing_together|throw_flash","target_id":<marker id>,"timing":{"mode":"now|on_cue|follow_player"}}}. swing_together allows now/on_cue/follow_player; throw_flash allows now/on_cue. "swing with me"/"with me" => follow_player.
- If the target region or marker is ambiguous or not in the vocabulary, return {"result":"clarify","question":"..."} asking one short question. Do NOT guess.
- If the comm asks for an action that does not exist (plant, defuse, rotate, buy, etc.), return {"result":"unsupported","reason":"..."}.
- If there is nothing to interpret, return {"result":"empty","reason":"..."}.
Do not add message_id, speaker_id, ticks, or any field not listed. Those are added by the trusted adapter later."""

FEW_SHOT = [
    ('two on heaven',
     '{"result":"report","payload":{"action":"report_enemy","region_id":"heaven","count":2,"hedge":"sure"}}'),
    ('i think someone\'s b main',
     '{"result":"report","payload":{"action":"report_enemy","region_id":"b_main","count":null,"hedge":"think"}}'),
    ('maybe one in pit',
     '{"result":"report","payload":{"action":"report_enemy","region_id":"b_pit","count":1,"hedge":"unsure"}}'),
    ('flash heaven on my cue',
     '{"result":"command","payload":{"action":"throw_flash","target_id":"heaven","timing":{"mode":"on_cue"}}}'),
    ('swing site with me',
     '{"result":"command","payload":{"action":"swing_together","target_id":"b_site","timing":{"mode":"follow_player"}}}'),
    ('flash that smoke',
     '{"result":"clarify","question":"Flash which smoke?"}'),
    ('go plant the spike',
     '{"result":"unsupported","reason":"no plant action in this contract"}'),
]


def _build_prompt(transcript: str, vocab: dict) -> str:
    lines = ["VOCABULARY:"]
    lines.append("region_ids: " + ", ".join(vocab["region_ids"]))
    callout_strs = [
        f"{c['region_name']} ({c['super_region_name']})"
        for c in vocab.get("callouts", []) if c.get("region_name")
    ]
    if callout_strs:
        lines.append("real callouts (for grounding spoken words): " + ", ".join(callout_strs))
    if vocab.get("agents"):
        for name, abilities in vocab["agents"].items():
            lines.append(f"agent {name}: abilities {', '.join(abilities)}")
    lines.append("abilities->primitive: " + ", ".join(
        f"{k}={v}" for k, v in vocab.get("primitives", {}).items()))
    lines.append("")
    lines.append("EXAMPLES:")
    for spoken, out in FEW_SHOT:
        lines.append(f'INPUT: {spoken}\nOUTPUT: {out}')
    lines.append("")
    lines.append(f"INPUT: {transcript}\nOUTPUT:")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Output validation — reject anything outside the frozen contract/vocabulary
# ---------------------------------------------------------------------------

def _validate_proposal(obj: dict, vocab: dict) -> Optional[dict]:
    """Return a normalized result dict if obj is a legal proposal, else None.

    None signals "illegal model output" -> caller falls back to deterministic parse.
    """
    if not isinstance(obj, dict):
        return None
    result = obj.get("result")
    regions = set(vocab["region_ids"])

    if result == "report":
        p = obj.get("payload")
        if not isinstance(p, dict):
            return None
        if p.get("action") != "report_enemy":
            return None
        if p.get("region_id") not in regions:
            return None
        count = p.get("count")
        if count is not None and not (isinstance(count, int) and not isinstance(count, bool) and count > 0):
            return None
        if p.get("hedge") not in HEDGES:
            return None
        return {"result": "report", "proposal": {"kind": "report", "payload": {
            "action": "report_enemy", "region_id": p["region_id"],
            "count": count, "hedge": p["hedge"]}}}

    if result == "command":
        p = obj.get("payload")
        if not isinstance(p, dict):
            return None
        action = p.get("action")
        if action not in COMMAND_ACTIONS:
            return None
        target = p.get("target_id")
        timing = p.get("timing")
        if not isinstance(timing, dict) or "mode" not in timing:
            return None
        mode = timing["mode"]
        allowed = SWING_TIMINGS if action == "swing_together" else FLASH_TIMINGS
        if mode not in allowed:
            return None
        # target must be a known region id (markers merge into regions until Person 1
        # supplies entry/flash marker ids; see docs note). Reject unknown tokens.
        if target not in regions:
            return None
        return {"result": "command", "proposal": {"kind": "command", "payload": {
            "action": action, "target_id": target, "timing": {"mode": mode}}}}

    if result == "clarify":
        q = obj.get("question")
        if not isinstance(q, str) or not q.strip():
            return None
        return {"result": "clarify", "question": q.strip()}

    if result == "unsupported":
        reason = obj.get("reason")
        return {"result": "unsupported", "reason": reason if isinstance(reason, str) else "unsupported action"}

    if result == "empty":
        reason = obj.get("reason")
        return {"result": "empty", "reason": reason if isinstance(reason, str) else "nothing to interpret"}

    return None


def _extract_json(text: str) -> Optional[dict]:
    """Pull the first JSON object out of model text; tolerant of stray prose/markdown."""
    text = text.strip()
    # strip markdown fences if present
    text = re.sub(r"^```(?:json)?|```$", "", text, flags=re.MULTILINE).strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    m = re.search(r"\{.*\}", text, flags=re.DOTALL)
    if m:
        try:
            return json.loads(m.group(0))
        except json.JSONDecodeError:
            return None
    return None


# ---------------------------------------------------------------------------
# Deterministic circuit breaker — required fallback, fully offline
# ---------------------------------------------------------------------------

def deterministic_interpret(transcript: str, vocab: dict) -> dict:
    """Keyword/alias parse of a transcript into the same proposal shape.

    This is the mandatory fallback used when the model is unavailable or illegal.
    It is intentionally conservative: resolve what it can from the vocabulary, ask
    to clarify on ambiguity, say unsupported for actions we do not have.
    """
    region_ids = vocab["region_ids"]
    raw = transcript.strip()
    text = raw.lower()
    if not text:
        return {"result": "empty", "reason": "nothing to interpret", "source": "deterministic",
                "transcript": transcript}

    base = {"source": "deterministic", "transcript": transcript}

    # 1. Unsupported actions first (honest "no", never invented behavior).
    for word in ("plant", "defuse", "rotate", "buy", "save", "reload"):
        if re.search(rf"\b{word}\b", text):
            return {**base, "result": "unsupported", "reason": f"no '{word}' action in this contract"}

    # 2. Flash command: "flash <region>"
    if re.search(r"\bflash\b", text):
        region = _find_region(text, region_ids)
        if region is None:
            return {**base, "result": "clarify", "question": "Flash where?"}
        mode = "on_cue" if re.search(r"\b(on (my )?cue|on my count|count)\b", text) else "now"
        return {**base, "result": "command", "proposal": {"kind": "command", "payload": {
            "action": "throw_flash", "target_id": region, "timing": {"mode": mode}}}}

    # 3. Swing command: "swing/peek <region>"
    if re.search(r"\b(swing|peek|push with me)\b", text):
        region = _find_region(text, region_ids)
        if region is None:
            return {**base, "result": "clarify", "question": "Swing which entrance?"}
        if re.search(r"\b(with me|together|follow)\b", text):
            mode = "follow_player"
        elif re.search(r"\b(on (my )?cue|on my count|count)\b", text):
            mode = "on_cue"
        else:
            mode = "now"
        return {**base, "result": "command", "proposal": {"kind": "command", "payload": {
            "action": "swing_together", "target_id": region, "timing": {"mode": mode}}}}

    # 4. Enemy report: a region plus (optionally) a count and a hedge.
    region = _find_region(text, region_ids)
    if region is not None:
        return {**base, "result": "report", "proposal": {"kind": "report", "payload": {
            "action": "report_enemy", "region_id": region,
            "count": _find_count(text), "hedge": _find_hedge(text)}}}

    # 5. Nothing matched a known region -> clarify rather than guess.
    return {**base, "result": "clarify", "question": "Where?"}


def _find_region(text: str, region_ids: list[str]) -> Optional[str]:
    # exact id tokens first (longest alias wins to avoid 'b' eating 'b main')
    for rid in sorted(region_ids, key=len, reverse=True):
        if re.search(rf"\b{re.escape(rid.replace('_', ' '))}\b", text) or rid in text:
            return rid
    for alias in sorted(V.REGION_ALIASES, key=len, reverse=True):
        if re.search(rf"\b{re.escape(alias)}\b", text):
            mapped = V.REGION_ALIASES[alias]
            if mapped in region_ids:
                return mapped
    return None


_NUM_WORDS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5}


def _find_count(text: str) -> Optional[int]:
    m = re.search(r"\b([1-5])\b", text)
    if m:
        return int(m.group(1))
    for word, n in _NUM_WORDS.items():
        if re.search(rf"\b{word}\b", text):
            return n
    return None  # never infer 1 from "someone"/"somebody"


def _find_hedge(text: str) -> str:
    for phrase in sorted(HEDGE_WORDS, key=len, reverse=True):
        if phrase in text:
            return HEDGE_WORDS[phrase]
    return "sure"


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def interpret(
    transcript: str,
    vocab: dict,
    client: Optional[ModelClient] = None,
    *,
    on_log: Optional[Callable[[dict], None]] = None,
) -> dict:
    """Interpret a transcript into a validated proposal.

    If `client` is given, try the model first; on ANY failure (exception, unparseable
    output, or output that fails vocabulary/contract validation) fall back to the
    deterministic parser. If `client` is None, go straight to deterministic.

    `on_log`, if given, receives a record dict (system, prompt, raw, parsed, source)
    for recording/decision_log; the caller owns writing it with copied inputs + tick.
    """
    system = SYSTEM_PROMPT
    prompt = _build_prompt(transcript, vocab)

    if client is not None:
        raw = None
        try:
            raw = client.generate(system, prompt)
            obj = _extract_json(raw or "")
            validated = _validate_proposal(obj, vocab) if obj is not None else None
            if validated is not None:
                out = {**validated, "source": "model", "transcript": transcript, "raw": raw}
                if on_log:
                    on_log({"system": system, "prompt": prompt, "raw": raw,
                            "parsed": validated, "source": "model"})
                return out
            # fell through: illegal/unparseable -> circuit breaker
        except Exception as exc:  # noqa: BLE001 - any model failure trips the breaker
            raw = f"<model error: {exc!r}>"

        fb = deterministic_interpret(transcript, vocab)
        fb["source"] = "deterministic_fallback"
        fb["raw"] = raw
        if on_log:
            on_log({"system": system, "prompt": prompt, "raw": raw,
                    "parsed": {k: v for k, v in fb.items() if k not in ("raw",)},
                    "source": "deterministic_fallback"})
        return fb

    # No model configured: deterministic path.
    fb = deterministic_interpret(transcript, vocab)
    if on_log:
        on_log({"system": system, "prompt": prompt, "raw": None,
                "parsed": fb, "source": "deterministic"})
    return fb
