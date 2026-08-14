"""
schemas/chatbot.py
==================
Pydantic models for the chatbot API.
"""
from pydantic import BaseModel, Field


class ChatMessageRequest(BaseModel):
    """Request body for POST /chatbot/message."""

    message: str = Field(..., min_length=1, max_length=2000, description="The user's message.")
    session_id: str | None = Field(
        default=None,
        description="Opaque session identifier for conversation continuity. "
                    "Pass back the value returned from the previous response.",
    )


class ChatMessageResponse(BaseModel):
    """Response body for POST /chatbot/message."""

    intent: str = Field(
        description=(
            "Classified intent. One of: "
            "wound_assessment | skin_assessment | symptom_assessment | "
            "needs_clarification | general_conversation"
        )
    )
    reply: str = Field(description="Natural-language AI reply to show the user.")
    session_id: str = Field(description="Session identifier to pass in the next request.")
