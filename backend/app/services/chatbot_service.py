"""
services/chatbot_service.py
============================
Chatbot service — Gemini intent classification with Redis conversation history.

Flow
----
1. Load this user's conversation history from Redis.
2. Append the new user message.
3. Send the full conversation to Gemini with a structured system prompt.
4. Parse the JSON response to extract ``intent`` and ``reply``.
5. Append the assistant response to history and persist back to Redis (TTL 30 min).
6. Return ``(intent, reply)`` to the caller.

Intents
-------
* ``wound_assessment``     — wounds, cuts, injuries, ulcers, sores
* ``skin_assessment``      — rashes, irritation, acne, moles, dryness, itching
* ``symptom_assessment``   — fever, headache, dizziness, nausea, fatigue, general unwell
* ``needs_clarification``  — vague / ambiguous — Gemini asks a follow-up question
* ``general_conversation`` — off-topic / casual — normal reply, no assessment CTA
"""

import json
import logging
import uuid
from typing import Literal
import asyncio

import httpx

from app.core.config import settings
from app.core.redis import redis_client

logger = logging.getLogger(__name__)

# ── Constants ─────────────────────────────────────────────────────────────────

_GEMINI_API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models"
    "/{model}:generateContent?key={api_key}"
)

_HISTORY_TTL = 1800  # 30 minutes

_VALID_INTENTS = frozenset(
    {
        "wound_assessment",
        "skin_assessment",
        "symptom_assessment",
        "needs_clarification",
        "general_conversation",
    }
)

# ── System prompt ─────────────────────────────────────────────────────────────

_SYSTEM_PROMPT = """\
You are Suri, a compassionate AI health assistant embedded in a mobile app.
The app offers three specialist assessment tools:
  1. Wound Assessment      – for wounds, cuts, lacerations, burns, ulcers, injuries, sores.
  2. Skin Assessment       – for skin conditions: rashes, acne, moles, irritation, \
dryness, itching, discoloration, eczema, psoriasis.
  3. Symptom Assessment    – for general health symptoms: fever, headache, dizziness, \
nausea, fatigue, cough, cold, flu, chest pain, or any general feeling of being unwell \
that doesn't fall clearly under wound or skin.

Your job:
  - Listen to the user's message(s) in context.
  - Determine which assessment tool best matches their concern, \
or whether to ask for more information, or simply have a normal conversation.
  - ALWAYS respond with a valid JSON object — no markdown, no extra text, just raw JSON.

JSON schema:
{
  "intent": "<one of: wound_assessment | skin_assessment | symptom_assessment | needs_clarification | general_conversation>",
  "reply": "<your natural-language response to the user>"
}

Guidelines:
  - Use "wound_assessment" when the user describes any physical wound or injury.
  - Use "skin_assessment" when the user describes a skin-related issue (not a wound).
  - Use "symptom_assessment" when the user describes general symptoms or feels unwell.
  - Use "needs_clarification" when the message is too vague to classify. \
    In your reply, ask a single, focused follow-up question.
  - Use "general_conversation" when the user is having casual conversation \
    that does not relate to health concerns.
  - Be empathetic, warm, and concise (2–3 sentences max for the reply).
  - Never recommend seeing a doctor in place of the in-app tools; \
    guide users to the appropriate tool first.
  - Do NOT wrap the JSON in a code block or add any text outside the JSON.
"""


# ── Service ───────────────────────────────────────────────────────────────────


class ChatbotService:
    """
    Process a single user message turn, classify intent via Gemini,
    and persist the conversation to Redis for multi-turn context.
    """

    async def process_message(
        self,
        user_id: int,
        message: str,
        session_id: str | None = None,
    ) -> tuple[str, str, str]:
        """
        Send the user's message to Gemini and return (intent, reply, session_id).

        Args:
            user_id:    Authenticated user's database ID (used for Redis key).
            message:    The user's latest message.
            session_id: Existing session ID to continue a conversation, or None to start fresh.

        Returns:
            Tuple of (intent, reply, session_id).
        """
        if not settings.GEMINI_API_KEY:
            raise ValueError("GEMINI_API_KEY is not configured in .env")

        # 1. Resolve or create session
        sid = session_id or str(uuid.uuid4())
        redis_key = f"chatbot:{user_id}:{sid}"

        # 2. Load history from Redis
        history: list[dict] = await self._load_history(redis_key)

        # 3. Append user message to history
        history.append({"role": "user", "parts": [{"text": message}]})

        # 4. Call Gemini
        intent, reply = await self._call_gemini(history)

        # 5. Append model response to history
        history.append({"role": "model", "parts": [{"text": json.dumps({"intent": intent, "reply": reply})}]})

        # 6. Persist updated history
        await self._save_history(redis_key, history)

        logger.info(
            "Chatbot turn user_id=%s session=%s intent=%s", user_id, sid, intent
        )
        return intent, reply, sid

    # ── Gemini ────────────────────────────────────────────────────────────────

    async def _call_gemini(
        self, history: list[dict]
    ) -> tuple[Literal["wound_assessment", "skin_assessment", "symptom_assessment", "needs_clarification", "general_conversation"], str]:
        """Send history to Gemini and parse the structured JSON response."""
        url = _GEMINI_API_URL.format(
            model=settings.GEMINI_MODEL,
            api_key=settings.GEMINI_API_KEY,
        )

        payload = {
            "system_instruction": {
                "parts": [{"text": _SYSTEM_PROMPT}]
            },
            "contents": history,
            "generationConfig": {
                "temperature": 0.2,
                "maxOutputTokens": 512,
                "responseMimeType": "application/json",
            },
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()

        data = response.json()

        try:
            raw_text: str = (
                data["candidates"][0]["content"]["parts"][0]["text"]
            )
            parsed = json.loads(raw_text)
            intent: str = parsed.get("intent", "general_conversation")
            reply: str = parsed.get("reply", "")

            # Guard against unexpected intents
            if intent not in _VALID_INTENTS:
                logger.warning("Unexpected Gemini intent %r — falling back to general_conversation", intent)
                intent = "general_conversation"

            return intent, reply  # type: ignore[return-value]

        except (KeyError, IndexError, json.JSONDecodeError) as exc:
            logger.exception("Failed to parse Gemini response: %s", exc)
            return "general_conversation", "I'm sorry, I couldn't process that. Could you try rephrasing?"

    # ── Redis helpers ─────────────────────────────────────────────────────────

    async def _load_history(self, redis_key: str) -> list[dict]:
        """Load conversation history from Redis, or return an empty list."""
        try:
            raw = await asyncio.to_thread(redis_client.get, redis_key)
            if raw:
                return json.loads(raw)
        except Exception as exc:
            logger.warning("Could not load chat history from Redis: %s", exc)
        return []

    async def _save_history(self, redis_key: str, history: list[dict]) -> None:
        """Persist conversation history to Redis with a rolling TTL."""
        # Keep only the last 20 turns to avoid unbounded growth
        if len(history) > 20:
            history = history[-20:]
        try:
            await asyncio.to_thread(
                redis_client.set, redis_key, json.dumps(history), ex=_HISTORY_TTL  # type: ignore[arg-type]
            )
        except Exception as exc:
            logger.warning("Could not save chat history to Redis: %s", exc)
