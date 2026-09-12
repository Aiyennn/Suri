"""
services/assessment_explanation_service.py
===========================================
Single-turn Gemini call that generates a short "What this could mean"
explanation from structured assessment context. Stateless — no chat history.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

_GEMINI_API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models"
    "/{model}:generateContent?key={api_key}"
)

_FALLBACK_EXPLANATION = (
    "Based on the image and information provided, a detailed explanation "
    "could not be generated at this time. Please refer to the clinical "
    "findings and recommendations above, and consult a healthcare "
    "professional if you have any concerns."
)

_SYSTEM_PROMPT = """\
You are a medical-writing assistant embedded in a wound-assessment app.
Your only task is to write a short "What this could mean" explanation for
the patient based on the structured assessment data you are given.

Rules — you MUST follow all of these without exception:

1. Use cautious, non-diagnostic language only. Permitted phrases include:
   "may be consistent with", "can occur with", "may suggest", "is often
   associated with", "may indicate". Never use language that implies
   certainty (e.g. "this is", "you have", "confirms").

2. Keep the response to 2–3 sentences in plain, patient-friendly language.
   Avoid clinical jargon.

3. Explain only how the supplied patient-reported symptoms and image
   observations may be consistent with the assessed wound type and healing
   stage. Do not introduce, infer, or assume any symptom, observation,
   cause, complication, risk, or clinical detail that was not supplied.

4. If the supplied confidence score is below 0.70, include a sentence noting
   that the image assessment is less certain and professional evaluation is
   especially important.

5. Do NOT add, modify, or remove urgency guidance, emergency instructions,
   recommendations, monitoring guidance, follow-up instructions, or referral
   advice. Those are handled separately by the rule engine.

6. Do NOT diagnose. Do not state or imply that the wound type, healing
   stage, or cause is definite.

7. Do NOT use any information from conversation history. Use only the
   structured assessment data supplied in the user message.

8. Respond with ONLY the plain-text explanation — no JSON, no headings,
   no markdown, no bullet points.
"""


@dataclass
class AssessmentContext:
    """Structured inputs used to generate the explanation."""

    symptoms: list[str]
    wound_type: str
    severity: str
    healing_stage: str
    redness: bool
    bleeding: str
    exudate_present: bool
    exudate_type: str
    exudate_amount: str
    triggered_rule_reasons: list[str]
    confidence: float


class AssessmentExplanationService:
    """
    Generates a plain-text "What this could mean" explanation for a wound
    assessment via a single, stateless Gemini call.
    """

    async def generate(self, context: AssessmentContext) -> str:
        """
        Generate a 2–3 sentence explanation from the given assessment context.

        Returns a neutral fallback string if Gemini is unavailable or returns
        an unusable response — never raises to the caller.
        """
        if not settings.GEMINI_API_KEY:
            logger.warning("GEMINI_API_KEY not configured — returning fallback explanation.")
            return _FALLBACK_EXPLANATION

        try:
            explanation = await self._call_gemini(self._build_user_message(context))
        except Exception as exc:
            logger.exception("Gemini call failed — returning fallback explanation: %s", exc)
            return _FALLBACK_EXPLANATION

        if not explanation or not explanation.strip():
            logger.warning("Gemini returned an empty response — returning fallback explanation.")
            return _FALLBACK_EXPLANATION

        return explanation.strip()

    def _build_user_message(self, ctx: AssessmentContext) -> str:
        """Serialise assessment context into a bounded user message for Gemini."""
        symptoms_str = ", ".join(ctx.symptoms) if ctx.symptoms else "none reported"

        exudate_desc = "none"
        if ctx.exudate_present:
            exudate_desc = f"{ctx.exudate_amount} amount of {ctx.exudate_type} exudate"

        reasons_str = (
            "\n".join(f"- {r}" for r in ctx.triggered_rule_reasons)
            if ctx.triggered_rule_reasons
            else "- None"
        )

        return (
            f"Assessment context:\n"
            f"\n"
            f"Patient-reported symptoms: {symptoms_str}\n"
            f"\n"
            f"Image observations:\n"
            f"  Redness present: {'yes' if ctx.redness else 'no'}\n"
            f"  Bleeding level: {ctx.bleeding}\n"
            f"  Exudate: {exudate_desc}\n"
            f"\n"
            f"AI assessment:\n"
            f"  Wound type: {ctx.wound_type}\n"
            f"  Severity: {ctx.severity}\n"
            f"  Healing stage: {ctx.healing_stage}\n"
            f"  Model confidence: {round(ctx.confidence * 100, 1)}%\n"
            f"\n"
            f"Triggered clinical finding reasons:\n"
            f"{reasons_str}\n"
            f"\n"
            f"Write the 'What this could mean' explanation using only the above."
        )

    async def _call_gemini(self, user_message: str) -> str:
        """Send a single-turn request to Gemini and return the plain-text response."""
        url = _GEMINI_API_URL.format(
            model=settings.GEMINI_MODEL,
            api_key=settings.GEMINI_API_KEY,
        )

        payload = {
            "system_instruction": {"parts": [{"text": _SYSTEM_PROMPT}]},
            "contents": [{"role": "user", "parts": [{"text": user_message}]}],
            "generationConfig": {
                "temperature": 0.3,
                "maxOutputTokens": 256,
            },
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()

        data = response.json()
        return data["candidates"][0]["content"]["parts"][0]["text"]
