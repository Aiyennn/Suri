"""
api/chatbot.py
==============
FastAPI router for the AI chatbot endpoint.

All routes are mounted under ``/chatbot`` by ``main.py``.

    POST /chatbot/message  – Send a user message; receive an intent + reply.
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.models.user import User
from app.schemas.chatbot import ChatMessageRequest, ChatMessageResponse
from app.services.auth_service import get_current_user
from app.services.chatbot_service import ChatbotService

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post(
    "/message",
    response_model=ChatMessageResponse,
    summary="Send a chatbot message",
    description=(
        "Send the user's message to the AI chatbot. "
        "Gemini classifies the intent and returns a natural-language reply. "
        "Pass ``session_id`` from the previous response to maintain conversation context."
    ),
)
async def send_message(
    req: ChatMessageRequest,
    current_user: User = Depends(get_current_user),
) -> ChatMessageResponse:
    """
    Process a single chatbot turn.

    1. Load conversation history from Redis for this user's session.
    2. Send history + new message to Gemini with a structured system prompt.
    3. Parse the JSON response to extract intent and reply.
    4. Persist updated history back to Redis.
    5. Return the intent and reply to the client.

    Raises:
        HTTPException(503): Gemini API key not configured or Gemini is unreachable.
    """
    service = ChatbotService()
    try:
        intent, reply, session_id = await service.process_message(
            user_id=current_user.id,
            message=req.message,
            session_id=req.session_id,
        )
    except ValueError as exc:
        # Raised when GEMINI_API_KEY is not set
        logger.error("Chatbot config error: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        )
    except Exception as exc:
        logger.exception("Chatbot processing failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="The AI service is temporarily unavailable. Please try again.",
        )

    return ChatMessageResponse(intent=intent, reply=reply, session_id=session_id)
